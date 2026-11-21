const fs = require('node:fs');
const path = require('node:path');

const distRoot = path.resolve(__dirname, '..', 'dist');
const srcRoot = path.resolve(__dirname, '..', 'src');

if (!fs.existsSync(distRoot)) {
  throw new Error(`Build output not found: ${distRoot}`);
}

function walk(directory) {
  const entries = fs.readdirSync(directory, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      rewriteFile(fullPath);
    }
  }
}

function rewriteFile(filePath) {
  let source = fs.readFileSync(filePath, 'utf8');
  const aliasPattern = /(require\(["'])(@\/[^"']+)(["']\))/g;
  let unresolved = [];

  source = source.replace(aliasPattern, (_match, prefix, specifier, suffix) => {
    const aliasTarget = specifier.slice(2);
    const sourceCandidate = path.resolve(srcRoot, aliasTarget);
    let target = path.resolve(distRoot, aliasTarget);

    if (!fs.existsSync(target) && fs.existsSync(`${target}.js`)) {
      target = `${target}.js`;
    } else if (!fs.existsSync(target) && fs.existsSync(path.join(target, 'index.js'))) {
      target = path.join(target, 'index.js');
    }

    const sourceExists =
      fs.existsSync(sourceCandidate) ||
      fs.existsSync(`${sourceCandidate}.ts`) ||
      fs.existsSync(path.join(sourceCandidate, 'index.ts'));

    if (!sourceExists || !fs.existsSync(target)) {
      unresolved.push(`${specifier} (${filePath})`);
      return `${prefix}${specifier}${suffix}`;
    }

    let relative = path.relative(path.dirname(filePath), target).split(path.sep).join('/');
    if (!relative.startsWith('.')) relative = `./${relative}`;
    if (relative.endsWith('.js')) relative = relative.slice(0, -3);
    return `${prefix}${relative}${suffix}`;
  });

  if (unresolved.length) {
    throw new Error(`Unresolved path aliases:\n${unresolved.join('\n')}`);
  }
  fs.writeFileSync(filePath, source);
}

walk(distRoot);

const unresolvedAlias = [];
walkForVerification(distRoot, unresolvedAlias);
if (unresolvedAlias.length) {
  throw new Error(`Compiled output still contains path aliases:\n${unresolvedAlias.join('\n')}`);
}

function walkForVerification(directory, matches) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) walkForVerification(fullPath, matches);
    else if (entry.isFile() && entry.name.endsWith('.js')) {
      if (/(?:require\(["'])@\//.test(fs.readFileSync(fullPath, 'utf8'))) {
        matches.push(fullPath);
      }
    }
  }
}


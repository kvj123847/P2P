import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common_widgets.dart';
import '../../mock_data/mock_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../content/course_details_screen.dart';
import 'tutor_profile_screen.dart';

/// Find Tutors + Content Library with search and filters.
class ExploreScreen extends StatefulWidget {
  final String? initialSubject;
  final int initialTab;

  const ExploreScreen({super.key, this.initialSubject, this.initialTab = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String? _subject;
  bool _freeOnly = false;
  bool _onlineOnly = false;
  CourseType? _type;
  String _sort = 'Top rated';

  @override
  void initState() {
    super.initState();
    _subject = widget.initialSubject;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesQuery(String text) =>
      text.toLowerCase().contains(_search.text.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    var tutors = state.visibleTutors.where((t) {
      final q = _matchesQuery(t.name) || t.subjects.any(_matchesQuery);
      final s = _subject == null || t.subjects.contains(_subject);
      final f = !_freeOnly || t.pricePerHour == 0;
      final o = !_onlineOnly || t.online;
      return q && s && f && o;
    }).toList();

    var courses = state.visibleCourses.where((c) {
      final q = _matchesQuery(c.title) || _matchesQuery(c.tutorName) || _matchesQuery(c.subject);
      final s = _subject == null || c.subject == _subject;
      final f = !_freeOnly || c.isFree;
      final t = _type == null || c.type == _type;
      return q && s && f && t;
    }).toList();

    if (_sort == 'Top rated') {
      tutors.sort((a, b) => b.rating.compareTo(a.rating));
      courses.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      tutors.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      courses.sort((a, b) => a.price.compareTo(b.price));
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Tutors'), Tab(text: 'Courses')],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or subject',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: _openFilters,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _chip('All', _subject == null, () => setState(() => _subject = null)),
                  for (final s in MockData.subjects)
                    _chip(s, _subject == s, () => setState(() => _subject = s)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Showing ${state.tier.short.toLowerCase()} tier only',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'Top rated', child: Text('Top rated')),
                      DropdownMenuItem(value: 'Lowest price', child: Text('Lowest price')),
                    ],
                    onChanged: (v) => setState(() => _sort = v ?? _sort),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  tutors.isEmpty
                      ? const EmptyState(
                          icon: Icons.person_search,
                          title: 'No tutors found',
                          message: 'Try a different subject or clear filters.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: tutors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => TutorCard(
                            tutor: tutors[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TutorProfileScreen(tutor: tutors[i])),
                            ),
                          ),
                        ),
                  courses.isEmpty
                      ? const EmptyState(
                          icon: Icons.menu_book,
                          title: 'No courses found',
                          message: 'Try a different subject or clear filters.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: courses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => CourseListTile(
                            course: courses[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CourseDetailsScreen(course: courses[i])),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback fn) {
            setSheet(fn);
            setState(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free only'),
                  value: _freeOnly,
                  onChanged: (v) => update(() => _freeOnly = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tutors online now'),
                  value: _onlineOnly,
                  onChanged: (v) => update(() => _onlineOnly = v),
                ),
                const SizedBox(height: 8),
                const Text('Course type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _type == null,
                      onSelected: (_) => update(() => _type = null),
                    ),
                    ChoiceChip(
                      label: const Text('Video'),
                      selected: _type == CourseType.video,
                      onSelected: (_) => update(() => _type = CourseType.video),
                    ),
                    ChoiceChip(
                      label: const Text('Text'),
                      selected: _type == CourseType.text,
                      onSelected: (_) => update(() => _type = CourseType.text),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'APPLY', onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          );
        },
      ),
    );
  }
}

import pytest

from core.errors import NotAParticipantError, TierMismatchError
from tests.conftest import make_identity


@pytest.mark.asyncio
async def test_conversation_requires_tier_compatibility(chat_manager, p1_client):
    make_identity(p1_client, "tok-a", "userA", "SCHOOL")
    make_identity(p1_client, "tok-b", "userB", "COLLEGE")

    with pytest.raises(TierMismatchError):
        await chat_manager.get_or_create_conversation(
            conversation_id=None, session_id=None, participant_ids=["userA", "userB"], tier="MIXED"
        )


@pytest.mark.asyncio
async def test_send_requires_participant(chat_manager, p1_client):
    make_identity(p1_client, "tok-a", "userA", "SCHOOL")
    make_identity(p1_client, "tok-b", "userB", "SCHOOL")
    convo = await chat_manager.get_or_create_conversation(
        conversation_id=None, session_id=None, participant_ids=["userA", "userB"], tier="SCHOOL"
    )

    with pytest.raises(NotAParticipantError):
        await chat_manager.send_message(conversation_id=convo.id, sender_id="intruder", body="hi")


@pytest.mark.asyncio
async def test_pagination_newest_first(chat_manager, p1_client):
    make_identity(p1_client, "tok-a", "userA", "SCHOOL")
    make_identity(p1_client, "tok-b", "userB", "SCHOOL")
    convo = await chat_manager.get_or_create_conversation(
        conversation_id=None, session_id=None, participant_ids=["userA", "userB"], tier="SCHOOL"
    )
    for i in range(5):
        await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body=f"msg{i}")

    page = chat_manager.get_messages_page(conversation_id=convo.id, limit=3)
    assert [m.body for m in page] == ["msg4", "msg3", "msg2"]


@pytest.mark.asyncio
async def test_backfill_since_last_received(chat_manager, p1_client):
    make_identity(p1_client, "tok-a", "userA", "SCHOOL")
    convo = await chat_manager.get_or_create_conversation(
        conversation_id=None, session_id=None, participant_ids=["userA"], tier="SCHOOL"
    )
    m1 = await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body="one")
    m2 = await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body="two")
    m3 = await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body="three")

    missed = chat_manager.get_messages_since(conversation_id=convo.id, last_received_message_id=m1.id)
    assert [m.id for m in missed] == [m2.id, m3.id]


@pytest.mark.asyncio
async def test_mark_read(chat_manager, p1_client):
    make_identity(p1_client, "tok-a", "userA", "SCHOOL")
    convo = await chat_manager.get_or_create_conversation(
        conversation_id=None, session_id=None, participant_ids=["userA"], tier="SCHOOL"
    )
    m1 = await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body="one")
    m2 = await chat_manager.send_message(conversation_id=convo.id, sender_id="userA", body="two")

    chat_manager.mark_read(conversation_id=convo.id, user_id="userB", up_to_message_id=m1.id)
    assert "userB" in m1.read_by
    assert "userB" not in m2.read_by

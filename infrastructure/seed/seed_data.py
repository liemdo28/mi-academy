"""Seed data — populates MI Academy DB with lessons, questions, and games."""

import asyncio
import json
import uuid

from sqlalchemy import select

from apps.api.game_catalog import BUILT_GAME_CATALOG
from apps.api.database import async_session_maker
from apps.api.models import (
    ContentVersion,
    Game,
    Lesson,
    Question,
    Reward,
    Subject,
)


async def seed_built_games(db) -> list[Game]:
    """Insert canonical built games that are not already present."""
    existing_game_types = {
        row[0] for row in (await db.execute(select(Game.game_type))).all()
    }
    games = [
        Game(
            id=entry.id,
            name=entry.name,
            game_type=entry.game_type,
            age_min=entry.age_min,
            age_max=entry.age_max,
            config_json=entry.config_json,
            is_active=True,
        )
        for entry in BUILT_GAME_CATALOG
        if entry.game_type not in existing_game_types
    ]
    for game in games:
        db.add(game)
    return games


async def seed():
    """Seed the database with MVP content."""
    async with async_session_maker() as db:
        # ── Subjects ──────────────────────────────────────────────────────────
        subjects = [
            Subject(
                id=str(uuid.uuid4()),
                name="Chữ cái & Từ vựng",
                code="letters",
                icon="🔤",
                order_index=1,
            ),
            Subject(
                id=str(uuid.uuid4()),
                name="Toán học",
                code="math",
                icon="🔢",
                order_index=2,
            ),
            Subject(
                id=str(uuid.uuid4()),
                name="Tư duy & Logic",
                code="logic",
                icon="🧩",
                order_index=3,
            ),
            Subject(
                id=str(uuid.uuid4()),
                name="Khoa học",
                code="science",
                icon="🔬",
                order_index=4,
            ),
            Subject(
                id=str(uuid.uuid4()),
                name="Kỹ năng sống",
                code="life_skills",
                icon="🌱",
                order_index=5,
            ),
        ]
        for s in subjects:
            db.add(s)

        await db.flush()

        # ── Lessons ────────────────────────────────────────────────────────────
        lessons = []
        lesson_data = [
            # Group A — Letters (junior)
            (
                "Nhận biết chữ cái A",
                subjects[0].id,
                "junior",
                1,
                "vi",
                "Học nhận biết chữ A hoa và a thường",
            ),
            (
                "Ghép chữ A",
                subjects[0].id,
                "junior",
                1,
                "vi",
                "Ghép các chữ cái để tạo từ bắt đầu bằng A",
            ),
            (
                "Nhận biết chữ cái E",
                subjects[0].id,
                "junior",
                1,
                "vi",
                "Học nhận biết chữ E hoa và e thường",
            ),
            (
                "Ghép từ đơn giản",
                subjects[0].id,
                "junior",
                2,
                "vi",
                "Ghép 2-3 chữ cái thành từ có nghĩa",
            ),
            (
                "Từ vựng về động vật",
                subjects[0].id,
                "junior",
                2,
                "vi",
                "Học từ vựng chỉ con vật quen thuộc",
            ),
            # Group B — Math (explorer)
            (
                "Phép cộng trong phạm vi 20",
                subjects[1].id,
                "explorer",
                1,
                "vi",
                "Học cộng các số từ 1 đến 20",
            ),
            (
                "Phép trừ trong phạm vi 20",
                subjects[1].id,
                "explorer",
                1,
                "vi",
                "Học trừ các số từ 1 đến 20",
            ),
            (
                "Bảng nhân 2 và 5",
                subjects[1].id,
                "explorer",
                2,
                "vi",
                "Học thuộc bảng nhân 2 và 5",
            ),
            (
                "Hình học cơ bản",
                subjects[1].id,
                "explorer",
                2,
                "vi",
                "Nhận biết hình tròn, vuông, tam giác, chữ nhật",
            ),
            (
                "Đo lường độ dài",
                subjects[1].id,
                "explorer",
                3,
                "vi",
                "So sánh và đo độ dài bằng thước",
            ),
            # Group C — Logic (master)
            (
                "Quy luật dãy số",
                subjects[2].id,
                "master",
                1,
                "vi",
                "Tìm quy luật trong dãy số để điền số tiếp theo",
            ),
            ("Sudoku 4x4", subjects[2].id, "master", 2, "vi", "Giải Sudoku cơ bản 4x4"),
            (
                "Mê cung toán học",
                subjects[2].id,
                "master",
                3,
                "vi",
                "Tìm đường trong mê cung bằng phép tính",
            ),
            # More lessons to reach 30
            (
                "Chữ cái O và U",
                subjects[0].id,
                "junior",
                2,
                "vi",
                "Học nhận biết chữ O và U",
            ),
            (
                "Từ vựng về màu sắc",
                subjects[0].id,
                "junior",
                2,
                "vi",
                "Học từ vựng các màu sắc",
            ),
            (
                "Phép cộng có nhớ",
                subjects[1].id,
                "explorer",
                2,
                "vi",
                "Học cộng có nhớ trong phạm vi 100",
            ),
            (
                "Phép trừ có nhớ",
                subjects[1].id,
                "explorer",
                2,
                "vi",
                "Học trừ có nhớ trong phạm vi 100",
            ),
            (
                "Bảng nhân 3 và 4",
                subjects[1].id,
                "explorer",
                3,
                "vi",
                "Học thuộc bảng nhân 3 và 4",
            ),
            (
                "Xem giờ trên đồng hồ",
                subjects[1].id,
                "explorer",
                2,
                "vi",
                "Học xem giờ đúng và giờ rưỡi",
            ),
            (
                "Nhận biết tiền Việt Nam",
                subjects[1].id,
                "explorer",
                3,
                "vi",
                "Nhận biết và đếm tiền Việt Nam",
            ),
            (
                "Câu đố logic",
                subjects[2].id,
                "master",
                1,
                "vi",
                "Giải các câu đố logic đơn giản",
            ),
            (
                "Pattern recognition",
                subjects[2].id,
                "master",
                2,
                "vi",
                "Nhận diện và tiếp tục dãy hình",
            ),
            (
                "Coding maze level 1",
                subjects[2].id,
                "master",
                1,
                "vi",
                "Điều khiển robot vượt mê cung bằng lệnh",
            ),
            (
                "Coding maze level 2",
                subjects[2].id,
                "master",
                2,
                "vi",
                "Sử dụng vòng lặp trong lập trình mê cung",
            ),
            (
                "Nguồn năng lượng",
                subjects[3].id,
                "explorer",
                1,
                "vi",
                "Tìm hiểu các nguồn năng lượng xung quanh",
            ),
            (
                "Chu trình nước",
                subjects[3].id,
                "explorer",
                2,
                "vi",
                "Tìm hiểu chu trình của nước trong tự nhiên",
            ),
            (
                "Cơ thể người",
                subjects[3].id,
                "explorer",
                3,
                "vi",
                "Các bộ phận chính của cơ thể người",
            ),
            (
                "Vệ sinh cá nhân",
                subjects[4].id,
                "junior",
                1,
                "vi",
                "Học rửa tay và giữ vệ sinh cá nhân",
            ),
            (
                "Kỹ năng giao tiếp",
                subjects[4].id,
                "explorer",
                2,
                "vi",
                "Học cách chào hỏi và nói lời cảm ơn",
            ),
            (
                "Quản lý thời gian",
                subjects[4].id,
                "master",
                3,
                "vi",
                "Học sắp xếp thời gian học tập hợp lý",
            ),
        ]

        for (
            title,
            subject_id,
            age_group,
            difficulty,
            language,
            description,
        ) in lesson_data:
            lesson = Lesson(
                id=str(uuid.uuid4()),
                subject_id=subject_id,
                title=title,
                description=description,
                age_group=age_group,
                difficulty=difficulty,
                language=language,
                estimated_minutes=5,
                is_active=True,
            )
            db.add(lesson)
            lessons.append(lesson)

        await db.flush()

        # ── Questions ─────────────────────────────────────────────────────────
        question_templates = [
            # Math questions
            {
                "lesson_id": lessons[5].id,
                "prompt": "5 + 3 = ?",
                "options": [6, 7, 8, 9],
                "answer": 8,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[5].id,
                "prompt": "12 + 7 = ?",
                "options": [17, 18, 19, 20],
                "answer": 19,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[5].id,
                "prompt": "8 + 6 = ?",
                "options": [12, 13, 14, 15],
                "answer": 14,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[6].id,
                "prompt": "10 - 4 = ?",
                "options": [4, 5, 6, 7],
                "answer": 6,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[6].id,
                "prompt": "15 - 8 = ?",
                "options": [6, 7, 8, 9],
                "answer": 7,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[7].id,
                "prompt": "2 × 4 = ?",
                "options": [6, 8, 10, 12],
                "answer": 8,
                "type": "multiple_choice",
                "diff": 2,
            },
            {
                "lesson_id": lessons[7].id,
                "prompt": "5 × 3 = ?",
                "options": [12, 15, 18, 20],
                "answer": 15,
                "type": "multiple_choice",
                "diff": 2,
            },
            {
                "lesson_id": lessons[7].id,
                "prompt": "2 × 7 = ?",
                "options": [12, 14, 16, 18],
                "answer": 14,
                "type": "multiple_choice",
                "diff": 2,
            },
            {
                "lesson_id": lessons[8].id,
                "prompt": "Hình nào có 4 cạnh bằng nhau?",
                "options": [
                    "Hình tròn",
                    "Hình vuông",
                    "Hình tam giác",
                    "Hình chữ nhật",
                ],
                "answer": "Hình vuông",
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[8].id,
                "prompt": "Hình nào không có góc?",
                "options": [
                    "Hình vuông",
                    "Hình chữ nhật",
                    "Hình tam giác",
                    "Hình tròn",
                ],
                "answer": "Hình tròn",
                "type": "multiple_choice",
                "diff": 1,
            },
            # Word questions
            {
                "lesson_id": lessons[0].id,
                "prompt": "Chữ nào sau đây là chữ A hoa?",
                "options": ["a", "A", "À", "Ă"],
                "answer": "A",
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[0].id,
                "prompt": "Chữ nào là chữ a thường?",
                "options": ["A", "a", "Â", "Ã"],
                "answer": "a",
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[3].id,
                "prompt": "Ghép các chữ: C - A - T = ?",
                "options": ["CAT", "ACT", "TAC", "CTA"],
                "answer": "CAT",
                "type": "multiple_choice",
                "diff": 2,
            },
            {
                "lesson_id": lessons[4].id,
                "prompt": "Con gì có 4 chân và sủa 'gâu gâu'?",
                "options": ["Mèo", "Chó", "Cá", "Chim"],
                "answer": "Chó",
                "type": "multiple_choice",
                "diff": 1,
            },
            # Logic questions
            {
                "lesson_id": lessons[10].id,
                "prompt": "Điền số tiếp theo: 2, 4, 6, 8, ?",
                "options": [9, 10, 11, 12],
                "answer": 10,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[10].id,
                "prompt": "Điền số tiếp theo: 1, 3, 5, 7, ?",
                "options": [8, 9, 10, 11],
                "answer": 9,
                "type": "multiple_choice",
                "diff": 1,
            },
            {
                "lesson_id": lessons[22].id,
                "prompt": "Mã ASCII của chữ 'A' là bao nhiêu?",
                "options": [64, 65, 66, 67],
                "answer": 65,
                "type": "multiple_choice",
                "diff": 3,
            },
        ]

        # Generate more questions to reach ~100
        for i in range(100):
            base = question_templates[i % len(question_templates)]
            q = Question(
                id=str(uuid.uuid4()),
                lesson_id=base["lesson_id"],
                question_type=base["type"],
                prompt=f"{base['prompt']} (#{i + 1})",
                options_json=json.dumps(base["options"]),
                correct_answer_json=json.dumps(base["answer"]),
                explanation="Giải thích cho câu hỏi này.",
                difficulty=base["diff"],
            )
            db.add(q)

        await db.flush()

        # ── Games ─────────────────────────────────────────────────────────────
        games = await seed_built_games(db)

        # ── Rewards ────────────────────────────────────────────────────────────
        rewards = [
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Sao đầu tiên",
                description="Hoàn thành bài học đầu tiên",
                unlock_requirement_json=json.dumps({"type": "first_lesson"}),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Học trò siêng năng",
                description="Hoàn thành 5 bài học",
                unlock_requirement_json=json.dumps(
                    {"type": "lessons_completed", "count": 5}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Bộ não nhạy bén",
                description="Hoàn thành 10 bài học",
                unlock_requirement_json=json.dumps(
                    {"type": "lessons_completed", "count": 10}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Chuyên gia chữ cái",
                description="Hoàn thành tất cả bài Nhóm A",
                unlock_requirement_json=json.dumps(
                    {"type": "group_completed", "group": "A"}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Phù thủy toán",
                description="Hoàn thành tất cả bài Nhóm B",
                unlock_requirement_json=json.dumps(
                    {"type": "group_completed", "group": "B"}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Thần đồng tư duy",
                description="Hoàn thành tất cả bài Nhóm C",
                unlock_requirement_json=json.dumps(
                    {"type": "group_completed", "group": "C"}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Nhà vô địch tuần",
                description="Hoàn thành 7 ngày liên tiếp",
                unlock_requirement_json=json.dumps({"type": "streak", "days": 7}),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Hoàn thành thử thách",
                description="Hoàn thành thử thách tư duy 5 lần",
                unlock_requirement_json=json.dumps(
                    {"type": "challenges_completed", "count": 5}
                ),
            ),
            Reward(
                id=str(uuid.uuid4()),
                reward_type="badge",
                name="Khám phá gia",
                description="Chơi ít nhất 1 game ở mỗi khu vực",
                unlock_requirement_json=json.dumps(
                    {"type": "areas_explored", "count": 3}
                ),
            ),
        ]
        for r in rewards:
            db.add(r)

        # ── Content Versions ────────────────────────────────────────────────
        for ct in ["lessons", "questions", "games"]:
            db.add(ContentVersion(content_type=ct, version=1, checksum=""))

        await db.flush()
        print(
            f"Seeded: {len(subjects)} subjects, {len(lessons)} lessons, ~100 questions, "
            f"{len(games)} games, {len(rewards)} rewards"
        )


if __name__ == "__main__":
    asyncio.run(seed())

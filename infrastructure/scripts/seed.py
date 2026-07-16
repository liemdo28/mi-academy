#!/usr/bin/env python3
"""Seed script for MI Academy — inserts 30 lessons + 500 questions.

Usage:
    python infrastructure/scripts/seed.py  # uses DATABASE_URL or sqlite fallback
"""
import os
import uuid
import json
import random
import hashlib
from datetime import datetime, timedelta

# Use sync SQLAlchemy for standalone script
from sqlalchemy import create_engine, text

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./mi_academy.db")
# Convert async URL to sync for script
if "asyncpg" in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("+asyncpg", "")
elif "aiosqlite" in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("+aiosqlite", "")

engine = create_engine(DATABASE_URL)


def gen_id():
    return str(uuid.uuid4())


def seed():
    with engine.begin() as conn:
        # Get subject IDs (already inserted by migration)
        result = conn.execute(text("SELECT id, code FROM subjects"))
        subjects = {row[1]: row[0] for row in result}

        # Get game IDs
        result = conn.execute(text("SELECT id, game_type FROM games"))
        games = {row[1]: row[0] for row in result}

        # Lesson definitions: (subject_code, title_vi, title_en, age_group, difficulty, lang, est_min, count)
        lessons = [
            ("letters", "Nhận biết chữ cái", "Letter Recognition", "junior", 1, "vi", 5),
            ("letters", "Âm và vần", "Sounds and Syllables", "junior", 2, "vi", 5),
            ("letters", "Viết chữ", "Handwriting", "junior", 2, "vi", 5),
            ("letters", "Ghép từ", "Word Formation", "explorer", 2, "vi", 5),
            ("letters", "Đọc đơn giản", "Simple Reading", "explorer", 3, "vi", 5),
            ("math", "Đếm số 1-20", "Counting 1-20", "junior", 1, "vi", 5),
            ("math", "Cộng số nhỏ", "Small Addition", "junior", 2, "vi", 5),
            ("math", "Trừ số nhỏ", "Small Subtraction", "junior", 2, "vi", 5),
            ("math", "Cộng trừ hỗn hợp", "Mixed +/-", "explorer", 3, "vi", 5),
            ("math", "Nhân chia cơ bản", "Basic Multiplication", "explorer", 3, "vi", 5),
            ("math", "Đọc giờ", "Telling Time", "explorer", 2, "vi", 5),
            ("math", "Tính tiền", "Money Calculation", "explorer", 3, "vi", 5),
            ("math", "Phân số", "Fractions", "master", 4, "vi", 5),
            ("logic", "Phân loại đồ vật", "Classify Objects", "junior", 1, "vi", 5),
            ("logic", "Trí nhớ", "Memory Games", "junior", 2, "vi", 5),
            ("logic", "Quy luật số", "Number Patterns", "explorer", 3, "vi", 5),
            ("logic", "So sánh", "Comparison", "explorer", 2, "vi", 5),
            ("logic", "Suy luận logic", "Logic Reasoning", "explorer", 3, "vi", 5),
            ("logic", "Puzzle tư duy", "Thinking Puzzles", "master", 4, "vi", 5),
            ("science", "Khoa học cơ bản", "Basic Science", "junior", 1, "vi", 5),
            ("science", "Hệ mặt trời", "Solar System", "explorer", 2, "vi", 5),
            ("science", "Động vật", "Animals", "junior", 1, "vi", 5),
            ("science", "Thực vật", "Plants", "explorer", 2, "vi", 5),
            ("science", "Cơ thể người", "Human Body", "explorer", 3, "vi", 5),
            ("creative", "Viết câu đơn", "Simple Sentences", "junior", 1, "vi", 5),
            ("creative", "Viết đoạn văn", "Paragraph Writing", "explorer", 2, "vi", 5),
            ("creative", "Lập trình trực quan", "Visual Programming", "explorer", 3, "vi", 5),
            ("creative", "Tư duy chiến lược", "Strategic Thinking", "master", 4, "vi", 5),
            ("creative", "Sáng tạo với hình", "Creative Drawing", "junior", 1, "vi", 5),
            ("creative", "Kể chuyện", "Storytelling", "explorer", 2, "vi", 5),
        ]

        lesson_ids = []
        for subj_code, title_vi, title_en, age, diff, lang, est in lessons:
            lid = gen_id()
            lesson_ids.append((lid, subj_code, title_vi, age, diff))
            content = {"steps": [
                {"type": "intro", "text": title_vi},
                {"type": "example"},
                {"type": "practice"},
                {"type": "game"},
                {"type": "summary"}
            ]}
            conn.execute(text("""
                INSERT INTO lessons (id, subject_id, title, description, age_group, difficulty, language, estimated_minutes, content_json, is_active)
                VALUES (:id, :sid, :title, :desc, :age, :diff, :lang, :est, :content, true)
            """), {
                "id": lid,
                "sid": subjects.get(subj_code, gen_id()),
                "title": title_vi,
                "desc": f"{title_vi} — {title_en}",
                "age": age,
                "diff": diff,
                "lang": lang,
                "est": est,
                "content": json.dumps(content),
            })

        # Question generators
        q_count = 0
        questions_per_lesson = 16  # ~16 * 30 = 480 ≈ 500

        # Question templates by type
        def mcq(prompt, options, correct_idx, explanation):
            return {
                "question_type": "multiple_choice",
                "prompt": prompt,
                "options_json": json.dumps(options),
                "correct_answer_json": json.dumps({"answer": correct_idx}),
                "explanation": explanation,
                "difficulty": 1,
            }

        def tf(prompt, is_true, explanation):
            return {
                "question_type": "true_false",
                "prompt": prompt,
                "options_json": json.dumps(["Đúng", "Sai"]),
                "correct_answer_json": json.dumps({"answer": 0 if is_true else 1}),
                "explanation": explanation,
                "difficulty": 1,
            }

        def fib(prompt, answer, explanation):
            return {
                "question_type": "fill_in_blank",
                "prompt": prompt,
                "options_json": json.dumps([]),
                "correct_answer_json": json.dumps({"answer": answer}),
                "explanation": explanation,
                "difficulty": 2,
            }

        def math_q(a, op, b):
            if op == "+":
                ans = a + b
            elif op == "-":
                ans = a - b
            elif op == "×":
                ans = a * b
            else:
                ans = a // b
            prompt = f"{a} {op} {b} = ?"
            options = [ans, ans + 1, ans - 1, ans + 2]
            random.shuffle(options)
            return mcq(prompt, [str(x) for x in options], options.index(ans), f"{a} {op} {b} = {ans}")

        # Generate questions for each lesson
        for lid, subj, title, age, diff in lesson_ids:
            random.seed(hashlib.md5(lid.encode()).hexdigest())
            qlist = []
            game_id = None

            if subj == "letters":
                qlist = [
                    mcq(f"Chữ nào đứng đầu trong '{title}'?", ["A", "B", "C", "D"], 0, "Chữ A luôn đứng đầu"),
                    tf("Chữ 'B' là chữ cái đầu tiên trong bảng chữ cái", False, "Chữ A là chữ cái đầu tiên"),
                    mcq("Từ 'MÈO' có bao nhiêu chữ cái?", ["2", "3", "4", "5"], 1, "M-È-O = 3 chữ"),
                    mcq("Âm đầu của từ 'NHÀ' là gì?", ["N", "NH", "A", "H"], 1, "NH là phụ âm ghép"),
                    tf("Chữ 'Z' có trong bảng chữ cái tiếng Việt", False, "Tiếng Việt không có chữ Z"),
                    mcq("Chữ nào là nguyên âm?", ["B", "A", "M", "T"], 1, "A là nguyên âm"),
                    fib("Hãy điền chữ còn lại: _EO", "M", "MEO = con mèo"),
                    mcq("Từ nào có 4 chữ cái?", ["MÈO", "NHÀ", "CHIM", "BÚT"], 2, "CHIM có 4 chữ"),
                    mcq("Âm cuối của 'HÀNH' là gì?", ["H", "A", "NH", "N"], 2, "NH là phụ âm cuối"),
                    tf("Từ 'BÉO' có 2 vần", False, "BÉ-O là 2 vần đúng, hoặc BÉO = 1 vần tùy cách ghép"),
                    mcq("Điền chữ thiếu: C_A", ["H", "A", "T", "O"], 0, "CHA"),
                    mcq("Từ nào là động vật?", ["MÈO", "BÀN", "GHẾ", "NHÀ"], 0, "MÈO là động vật"),
                    mcq("Âm đầu của 'PHỐ' là gì?", ["P", "PH", "O", "F"], 1, "PH là phụ âm ghép"),
                    tf("Tiếng Việt có 29 chữ cái", True, "Đúng, 29 chữ cái"),
                    mcq("Chữ nào có dấu ngã?", ["Ã", "Á", "À", "Ạ"], 0, "Ã là dấu ngã"),
                    fib("Hãy điền: T_M", "A", "TAM = số 3"),
                ]
            elif subj == "math":
                r = random.Random(hashlib.md5((lid + "m").encode()).hexdigest())
                qlist = []
                for i in range(6):
                    a, b = r.randint(1, 10), r.randint(1, 10)
                    qlist.append(math_q(a, "+", b))
                for i in range(5):
                    a, b = r.randint(5, 15), r.randint(1, 5)
                    qlist.append(math_q(a, "-", b))
                qlist += [
                    tf("5 + 5 = 10", True, "5 + 5 = 10"),
                    mcq("Số nào lớn hơn 10?", ["8", "9", "11", "7"], 2, "11 > 10"),
                    mcq("Giờ nào đúng 12 giờ trưa?", ["12:00", "11:00", "1:00", "6:00"], 0, "12:00 là trưa"),
                    fib("10 - 4 = ?", "6", "10 - 4 = 6"),
                ]
                game_id = games.get("math_race")
            elif subj == "logic":
                qlist = [
                    mcq("Loại nào khác với nhóm còn lại?", ["MÈO", "CHÓ", "CÁ", "XE"], 2, "CÁ bơi dưới nước, còn lại trên cạn"),
                    tf("Hình tròn có 3 cạnh", False, "Hình tròn không có cạnh"),
                    mcq("Số tiếp theo: 2, 4, 6, ?", ["7", "8", "9", "10"], 1, "Quy luật +2"),
                    mcq("Cái nào to nhất?", ["Voi", "Mèo", "Chuột", "Chó"], 0, "Voi to nhất"),
                    mcq("Loại nào là quả?", ["CÀ RỐT", "TÁO", "KHOAI", "HÀNH"], 1, "TÁO là quả"),
                    tf("Hình vuông có 4 cạnh bằng nhau", True, "Đúng"),
                    mcq("Số thiếu: 1, 2, ?, 4", ["3", "5", "6", "0"], 0, "3"),
                    mcq("Đâu là màu nóng?", ["Xanh", "Đỏ", "Tím", "Xám"], 1, "Đỏ là màu nóng"),
                    fib("Sau 5 là số ?", "6", "5 + 1 = 6"),
                    mcq("Cái nào dùng để viết?", ["BÚT", "MUỖNG", "DĨA", "CHÉN"], 0, "BÚT để viết"),
                    tf("Mặt trời chiếu sáng ban ngày", True, "Đúng"),
                    mcq("Cái nào không thuộc nhóm?", ["NHÀ", "TRƯỜNG", "BỆNH VIỆN", "CON MÈO"], 3, "CON MÈO là động vật"),
                    mcq("Số lớn nhất trong 3, 7, 1, 9 là?", ["3", "7", "1", "9"], 3, "9 lớn nhất"),
                    mcq("Quy luật: ▲▲▼▲▲▼▲▲?", ["▲", "▼", "■", "●"], 1, "▼ theo quy luật"),
                    mcq("Hình nào có 3 cạnh?", ["Vuông", "Tròn", "Tam giác", "Chữ nhật"], 2, "Tam giác có 3 cạnh"),
                    fib("Hết", "0", "Khi hết = 0"),
                ]
                game_id = games.get("robot_commands")
            elif subj == "science":
                qlist = [
                    mcq("Hành tinh nào gần mặt trời nhất?", ["Trái Đất", "Sao Thủy", "Sao Hỏa", "Sao Kim"], 1, "Sao Thủy"),
                    tf("Nước sôi ở 100 độ C", True, "Đúng"),
                    mcq("Con nào đẻ trứng?", ["Gà", "Chó", "Mèo", "Bò"], 0, "Gà đẻ trứng"),
                    mcq("Bộ phận nào dùng để thở?", ["Tim", "Phổi", "Gan", "Dạ dày"], 1, "Phổi"),
                    mcq("Cây quang hợp nhờ?", ["Đất", "Ánh sáng", "Gió", "Mưa"], 1, "Ánh sáng mặt trời"),
                    tf("Mặt trăng tự phát sáng", False, "Mặt trăng phản chiếu ánh sáng mặt trời"),
                    mcq("Thế giới có bao nhiêu đại dương?", ["3", "4", "5", "6"], 2, "5 đại dương"),
                    mcq("Động vật ăn cỏ là?", ["Sư tử", "Bò", "Hổ", "Cá sấu"], 1, "Bò ăn cỏ"),
                    mcq("Nhiệt độ đóng băng của nước?", ["0°C", "10°C", "50°C", "100°C"], 0, "0°C"),
                    tf("Oxy cần cho sự sống", True, "Đúng, oxy rất cần thiết"),
                    mcq("Sao nào gần Trái Đất nhất?", ["Sao Sirius", "Mặt Trời", "Sao Bắc Cực", "Sao Hỏa"], 1, "Mặt Trời"),
                    mcq("Rễ cây làm gì?", ["Hấp thụ nước", "Quang hợp", "Thở", "Bay"], 0, "Rễ hấp thụ nước và chất dinh dưỡng"),
                    mcq("Xương người có bao nhiêu cái?", ["106", "206", "306", "406"], 1, "206 xương"),
                    tf("Kim loại dẫn điện tốt", True, "Đúng"),
                    mcq("Nước chiếm bao nhiêu Trái Đất?", ["50%", "60%", "71%", "80%"], 2, "Khoảng 71%"),
                    mcq("Con nào có vảy?", ["Cá", "Chó", "Mèo", "Gà"], 0, "Cá có vảy"),
                ]
                game_id = games.get("memory_cards")
            elif subj == "creative":
                qlist = [
                    mcq("Câu nào đúng ngữ pháp?", ["Tôi đi học", "Đi học tôi", "Học tôi đi", "Tôi học đi"], 0, "Tôi đi học"),
                    tf("Một đoạn văn có 3-5 câu", True, "Đúng"),
                    mcq("Robot cần gì để di chuyển?", ["Lệnh", "Pin", "Cả hai", "Không cần gì"], 2, "Cả lệnh và pin"),
                    mcq("Trong lập trình, 'vòng lặp' là gì?", ["Lặp lại", "Dừng lại", "Xóa", "Tạo mới"], 0, "Lặp lại lệnh"),
                    mcq("Câu nào kể chuyện hay hơn?", ["Con mèo chạy", "Con mèo lông vàng chạy nhanh trên sân"), 1, "Chi tiết hơn = hay hơn")

                    mcq("Câu nào kể chuyện hay hơn?", ["Con mèo chạy", "Con mèo lông vàng chạy nhanh trên sân"], 1, "Chi tiết hơn = hay hơn"),
                ]

            # Insert questions: up to questions_per_lesson, pad if needed
            inserted = 0
            for q in qlist[:questions_per_lesson]:
                qid = gen_id()
                conn.execute(text("""
                    INSERT INTO questions (id, lesson_id, question_type, prompt, options_json, correct_answer_json, explanation, difficulty)
                    VALUES (:id, :lid, :qt, :prompt, :opt, :ans, :expl, :diff)
                """), {
                    "id": qid, "lid": lid, "qt": q["question_type"],
                    "prompt": q["prompt"], "opt": q["options_json"],
                    "ans": q["correct_answer_json"], "expl": q["explanation"],
                    "diff": q.get("difficulty", 1),
                })
                inserted += 1
                q_count += 1

            while inserted < questions_per_lesson:
                qid = gen_id()
                conn.execute(text("""
                    INSERT INTO questions (id, lesson_id, question_type, prompt, options_json, correct_answer_json, explanation, difficulty)
                    VALUES (:id, :lid, :qt, :prompt, :opt, :ans, :expl, :diff)
                """), {
                    "id": qid, "lid": lid, "qt": "multiple_choice",
                    "prompt": f"Câu hỏi {inserted + 1} về {title}",
                    "opt": json.dumps(["A", "B", "C", "D"]),
                    "ans": json.dumps({"answer": 0}),
                    "expl": "Giải thích.", "diff": diff,
                })
                inserted += 1
                q_count += 1

        for ctype in ["lessons", "questions", "games"]:
            conn.execute(text(
                "INSERT INTO content_versions (content_type, version, checksum, created_at) VALUES (:ct, 1, :chk, :now)"
            ), {"ct": ctype, "chk": hashlib.sha256(ctype.encode()).hexdigest(), "now": datetime.utcnow()})

        print(f"Seeded {len(lesson_ids)} lessons and {q_count} questions.")


if __name__ == "__main__":
    seed()

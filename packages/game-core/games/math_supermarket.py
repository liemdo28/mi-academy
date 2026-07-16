import random
from packages.game_core.base import GameEngineBase, GameConfig, LevelState, AnswerResult, HintResult


class MathSupermarketGame(GameEngineBase):
    ITEMS_DB = [
        {"name": "tao", "price": 5000, "unit": "quy"},
        {"name": "chuoi", "price": 3000, "unit": "nhanh"},
        {"name": "sua", "price": 15000, "unit": "hop"},
        {"name": "banh mi", "price": 8000, "unit": "cai"},
        {"name": "keo", "price": 2000, "unit": "cai"},
        {"name": "nuoc", "price": 5000, "unit": "chai"},
        {"name": "socola", "price": 12000, "unit": "thanh"},
        {"name": "cam", "price": 4000, "unit": "quy"},
        {"name": "mit", "price": 25000, "unit": "quy"},
        {"name": "xu", "price": 7000, "unit": "kg"},
    ]

    def _get_mode(self, level):
        if level <= 2: return "calculate_total"
        if level <= 4: return "calculate_change"
        if level <= 6: return "select_items"
        return "compare_prices"

    def load_level(self, level):
        level = max(1, min(10, level))
        mode = self._get_mode(level)
        items = []
        rnd = random.Random(level * 777 + self.config.game_type.__hash__())
        num_q = 5
        for _ in range(num_q):
            n_shop = rnd.randint(1, min(3 + level // 2, len(self.ITEMS_DB)))
            basket = rnd.sample(self.ITEMS_DB, n_shop)
            qty_map = {}
            for si in basket:
                qty_map[si["name"]] = rnd.randint(1, 3)
            total = sum(si["price"] * qty_map[si["name"]] for si in basket)

            if mode == "calculate_total":
                desc = " + ".join(str(qty_map[si["name"]]) + "x" + si["name"] for si in basket)
                qstr = desc + " = ?"
                ans = total
            elif mode == "calculate_change":
                paid = rnd.choice([total + 10000, total + 5000, total + 20000])
                qstr = "Tong: " + str(total) + "d, Khach tra: " + str(paid) + "d, Tra lai: ?"
                ans = paid - total
            elif mode == "select_items":
                budget = rnd.randint(total + 2000, total + 15000)
                qstr = "Ngan sach: " + str(budget) + "d, tong: " + str(total) + "d, con lai: ?"
                ans = budget - total
            else:
                other = rnd.sample(self.ITEMS_DB, n_shop)
                other_qty = {si["name"]: rnd.randint(1, 3) for si in other}
                other_total = sum(si["price"] * other_qty[si["name"]] for si in other)
                if other_total == total: other_total += 5000
                qstr = "Gio A: " + str(total) + "d, Gio B: " + str(other_total) + "d, Gia re hon?"
                ans = total if total < other_total else other_total
            opts = [ans]
            for _ in range(3):
                d = ans + rnd.choice([-5000, -2000, 2000, 5000])
                if d not in opts: opts.append(d)
            rnd.shuffle(opts)
            items.append({"question": qstr, "basket": basket, "qty_map": qty_map, "options": opts, "correct_answer": ans, "mode": mode, "hint": "Dem ky nhe", "explanation": "Dap an: " + str(ans) + "d"})
        self._state = LevelState(level=level, items=items, difficulty=level, current_index=0, total_questions=len(items))
        return self._state

    def submit_answer(self, answer):
        if self._state is None: raise RuntimeError("Level not loaded")
        if self._state.current_index >= len(self._state.items):
            return AnswerResult(is_correct=False, correct_answer="", explanation="No more", next_state=None, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=False)
        item = self._state.items[self._state.current_index]
        correct = item["correct_answer"]
        try:
            user = int(answer) if not isinstance(answer, str) else int(answer.strip())
        except Exception:
            user = None
        ok = (user == correct)
        if ok:
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            ns = self._state if self._state.current_index < len(self._state.items) else None
            return AnswerResult(is_correct=True, correct_answer=correct, explanation=item.get("explanation"), next_state=ns, stars_earned=stars, hints_remaining=self._hints_remaining, retry_allowed=False)
        self._retry_count += 1
        return AnswerResult(is_correct=False, correct_answer=correct, explanation=None, next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=self._retry_count < 3)

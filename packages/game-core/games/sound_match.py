import random
from packages.game_core.base import GameEngineBase, GameConfig, LevelState, AnswerResult, HintResult


class SoundMatchGame(GameEngineBase):
    LETTER_ITEMS = {
        "a": {"phoneme": "ah", "image_key": "apple", "letter": "a"},
        "b": {"phoneme": "buh", "image_key": "ball", "letter": "b"},
        "c": {"phoneme": "kuh", "image_key": "cat", "letter": "c"},
        "d": {"phoneme": "duh", "image_key": "dog", "letter": "d"},
        "e": {"phoneme": "eh", "image_key": "egg", "letter": "e"},
        "f": {"phoneme": "fuh", "image_key": "fish", "letter": "f"},
        "g": {"phoneme": "guh", "image_key": "goat", "letter": "g"},
        "h": {"phoneme": "huh", "image_key": "hat", "letter": "h"},
        "i": {"phoneme": "ih", "image_key": "insect", "letter": "i"},
        "j": {"phoneme": "juh", "image_key": "jar", "letter": "j"},
        "k": {"phoneme": "kuh", "image_key": "kite", "letter": "k"},
        "l": {"phoneme": "luh", "image_key": "lion", "letter": "l"},
        "m": {"phoneme": "muh", "image_key": "moon", "letter": "m"},
        "n": {"phoneme": "nuh", "image_key": "nest", "letter": "n"},
        "o": {"phoneme": "ah", "image_key": "orange", "letter": "o"},
        "p": {"phoneme": "puh", "image_key": "pig", "letter": "p"},
        "r": {"phoneme": "ruh", "image_key": "rabbit", "letter": "r"},
        "s": {"phoneme": "sss", "image_key": "sun", "letter": "s"},
        "t": {"phoneme": "tuh", "image_key": "tree", "letter": "t"},
        "u": {"phoneme": "uh", "image_key": "umbrella", "letter": "u"},
    }
    WORD_PAIRS = [["cat","hat","bat","rat"],["dog","log","fog","hog"],["sun","run","fun","bun"],["fish","dish","wish"],["tree","three","free"],["book","cook","hook","look"],["apple","maple","purple"],["orange","range","change"]]
    SENTENCES = [["The cat sleeps.","The cat runs.","The cat eats."],["The dog barks.","The dog walks.","The dog eats."],["I see a bird.","I see a fish.","I see a cat."],["The sun is bright.","The moon is bright.","The star is bright."]]


    def __init__(self, config):
        super().__init__(config)
        self._replay_count = 0
        self._max_replays = 3
    def _get_mode(self, level):
        if level <= 2: return "letter_match"
        elif level <= 4: return "initial_sound"
        elif level <= 7: return "word_match"
        return "sentence_match"
    def load_level(self, level):
        level = max(1, min(10, level))
        mode = self._get_mode(level)
        items = []
        if mode == "letter_match":
            keys = list(self.LETTER_ITEMS.keys())
            for lk in random.sample(keys, min(4, len(keys))):
                ld = self.LETTER_ITEMS[lk]
                opts = random.sample([k for k in keys if k != lk], 2) + [lk]
                random.shuffle(opts)
                items.append({"audio_key": lk, "mode": mode, "options": opts[:3], "correct_answer": lk, "phoneme": ld["phoneme"], "image_key": ld["image_key"], "hint": "Nghe am va chon chu cai dung", "explanation": "Chu cai la " + lk})
        elif mode in ("initial_sound", "word_match"):
            for pair in random.sample(self.WORD_PAIRS, min(4, len(self.WORD_PAIRS))):
                correct = pair[0]
                opts = list(dict.fromkeys(list(pair) + [correct]))[:3]
                random.shuffle(opts)
                items.append({"audio_key": correct, "mode": mode, "options": opts, "correct_answer": correct, "initial_sound": correct[0], "hint": "Chon tu bat dau bang am " + correct[0], "explanation": correct + " la dap an"})
        else:
            for sl in random.sample(self.SENTENCES, min(3, len(self.SENTENCES))):
                correct = sl[0]
                opts = sl[:3]
                random.shuffle(opts)
                items.append({"audio_key": correct, "mode": mode, "options": opts, "correct_answer": correct, "hint": "Nghe cau va chon dung", "explanation": correct})
        self._state = LevelState(level=level, items=items, difficulty=level, current_index=0, total_questions=len(items))
        self._replay_count = 0
        return self._state
    def start(self):
        super().start()
        self._replay_count = 0
    def submit_answer(self, answer):
        if self._state is None: raise RuntimeError("Level not loaded")
        if self._state.current_index >= len(self._state.items):
            return AnswerResult(is_correct=False, correct_answer="", explanation="No more", next_state=None, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=False)
        item = self._state.items[self._state.current_index]
        correct = item["correct_answer"]
        ok = str(answer).strip().lower() == str(correct).strip().lower()
        if ok:
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            ns = self._state if self._state.current_index < len(self._state.items) else None
            return AnswerResult(is_correct=True, correct_answer=correct, explanation=item.get("explanation"), next_state=ns, stars_earned=stars, hints_remaining=self._hints_remaining, retry_allowed=False)
        self._retry_count += 1
        return AnswerResult(is_correct=False, correct_answer=correct, explanation=None, next_state=self._state, stars_earned=0, hints_remaining=self._hints_remaining, retry_allowed=self._retry_count < 3)
    def replay_audio(self):
        if self._replay_count < self._max_replays:
            self._replay_count += 1
            return True
        return False
    def get_replays_remaining(self):
        return max(0, self._max_replays - self._replay_count)
    def use_hint(self):
        if self._hints_remaining <= 0: return HintResult(hint_text="", hints_remaining=0, hint_given=False)
        if self._state is None or self._state.current_index >= len(self._state.items): return HintResult(hint_text="", hints_remaining=self._hints_remaining, hint_given=False)
        item = self._state.items[self._state.current_index]
        self._hints_remaining -= 1
        return HintResult(hint_text=item.get("hint", "Nghe ky nhe"), hints_remaining=self._hints_remaining, hint_given=True)

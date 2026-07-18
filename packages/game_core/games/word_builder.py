import random
from packages.game_core.base import GameEngineBase, LevelState


class WordBuilderGame(GameEngineBase):
    WORD_BANKS = {
        1: [
            {"word": "me", "image_key": "person", "hint": "One person"},
            {"word": "hi", "image_key": "wave", "hint": "A greeting"},
            {"word": "cat", "image_key": "cat", "hint": "Says meow"},
            {"word": "dog", "image_key": "dog", "hint": "Says woof"},
            {"word": "meo", "image_key": "cat", "hint": "Con vat"},
            {"word": "ca", "image_key": "fish", "hint": "Song nuoc"},
        ],
        2: [
            {"word": "sun", "image_key": "sun", "hint": "Shines sky"},
            {"word": "run", "image_key": "run", "hint": "Fast move"},
            {"word": "hat", "image_key": "hat", "hint": "Head wear"},
            {"word": "nha", "image_key": "house", "hint": "Noi o"},
            {"word": "but", "image_key": "pen", "hint": "Dung viet"},
            {"word": "cay", "image_key": "tree", "hint": "Co rong"},
        ],
        3: [
            {"word": "tree", "image_key": "tree", "hint": "Birds nest"},
            {"word": "fish", "image_key": "fish", "hint": "Swims water"},
            {"word": "bird", "image_key": "bird", "hint": "Flies sky"},
            {"word": "book", "image_key": "book", "hint": "Read this"},
            {"word": "happy", "image_key": "smile", "hint": "Feel good"},
        ],
        4: [
            {"word": "water", "image_key": "water", "hint": "Drink live"},
            {"word": "house", "image_key": "house", "hint": "Where live"},
            {"word": "apple", "image_key": "apple", "hint": "Red fruit"},
            {"word": "mouse", "image_key": "mouse", "hint": "Small whiskers"},
            {"word": "flower", "image_key": "flower", "hint": "Blooms spring"},
        ],
        5: [
            {"word": "banana", "image_key": "banana", "hint": "Yellow fruit"},
            {"word": "orange", "image_key": "orange", "hint": "Citrus fruit"},
            {"word": "planet", "image_key": "planet", "hint": "Orbits sun"},
            {"word": "turtle", "image_key": "turtle", "hint": "Slow reptile"},
            {"word": "rabbit", "image_key": "rabbit", "hint": "Long ears"},
        ],
        6: [
            {"word": "purple", "image_key": "purple", "hint": "Color blue red"},
            {"word": "bridge", "image_key": "bridge", "hint": "Crosses river"},
            {"word": "forest", "image_key": "forest", "hint": "Many trees"},
            {"word": "pencil", "image_key": "pencil", "hint": "Write draw"},
            {"word": "garden", "image_key": "garden", "hint": "Flowers grow"},
        ],
        7: [
            {"word": "dolphin", "image_key": "dolphin", "hint": "Smart sea"},
            {"word": "rainbow", "image_key": "rainbow", "hint": "After rain"},
            {"word": "penguin", "image_key": "penguin", "hint": "Cold place"},
            {"word": "chicken", "image_key": "chicken", "hint": "Farm animal"},
            {"word": "monster", "image_key": "monster", "hint": "Scary creature"},
        ],
        8: [
            {"word": "elephant", "image_key": "elephant", "hint": "Largest land"},
            {"word": "treasure", "image_key": "treasure", "hint": "Hidden gold"},
            {"word": "calendar", "image_key": "calendar", "hint": "Shows months"},
            {"word": "computer", "image_key": "computer", "hint": "Electronic"},
            {"word": "mountain", "image_key": "mountain", "hint": "Tall land"},
        ],
    }

    def __init__(self, config):
        super().__init__(config)
        self._current_word_index = 0

    def load_level(self, level):
        level = max(1, min(10, level))
        bank = self.WORD_BANKS.get(level, self.WORD_BANKS[max(1, min(8, level))])
        items = random.sample(bank, min(len(bank), 4))
        enriched = []
        for item in items:
            word = item["word"]
            letters = list(word.upper())
            random.shuffle(letters)
            mode = (
                "full_word"
                if level <= 2
                else "missing_letter"
                if level <= 4
                else "no_hint"
            )
            enriched.append(
                {
                    "word": word,
                    "letters": letters,
                    "shuffled_letters": letters,
                    "correct_answer": word.lower(),
                    "image_key": item.get("image_key", "word"),
                    "level_mode": mode,
                    "hint": item.get("hint", "Arrange letters"),
                    "explanation": f"The word is: {word}",
                }
            )
        self._state = LevelState(
            level=level,
            items=enriched,
            difficulty=level,
            current_index=0,
            total_questions=len(enriched),
        )
        self._current_word_index = 0
        return self._state

    def start(self):
        super().start()
        self._current_word_index = 0

    def submit_answer(self, answer):
        from packages.game_core.base import AnswerResult

        if self._state is None:
            raise RuntimeError("Level not loaded")
        if self._state.current_index >= len(self._state.items):
            return AnswerResult(
                is_correct=False,
                correct_answer="",
                explanation="No more questions",
                next_state=None,
                stars_earned=0,
                hints_remaining=self._hints_remaining,
                retry_allowed=False,
            )
        item = self._state.items[self._state.current_index]
        correct = item["correct_answer"]
        user = answer.strip().lower()
        is_correct = user == correct
        if is_correct:
            stars = self._calculate_stars_for_question()
            self._stars_per_question.append(stars)
            self._state.current_index += 1
            next_state = (
                self._state
                if self._state.current_index < len(self._state.items)
                else None
            )
            return AnswerResult(
                is_correct=True,
                correct_answer=correct,
                explanation=item.get("explanation"),
                next_state=next_state,
                stars_earned=stars,
                hints_remaining=self._hints_remaining,
                retry_allowed=False,
            )
        else:
            self._retry_count += 1
            return AnswerResult(
                is_correct=False,
                correct_answer=correct,
                explanation=None,
                next_state=self._state,
                stars_earned=0,
                hints_remaining=self._hints_remaining,
                retry_allowed=self._retry_count < 3,
            )

    def get_current_letters(self):
        if self._state is None or self._state.current_index >= len(self._state.items):
            return []
        return self._state.items[self._state.current_index].get("shuffled_letters", [])

    def get_current_word_hint(self):
        if self._state is None or self._state.current_index >= len(self._state.items):
            return ""
        return self._state.items[self._state.current_index].get(
            "hint", "Arrange letters"
        )

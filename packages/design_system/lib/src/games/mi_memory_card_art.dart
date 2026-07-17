import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Original Memory Cards illustrations — Animals theme (8 pairs), per
/// design/games/memory-cards/MEMORY_CARDS_ASSET_KIT.md.
enum MiMemoryAnimal { cat, dog, fish, bird, rabbit, frog, elephant, bee }

/// Maps a raw emoji glyph — as currently stored in `memory_cards.json` level
/// content — to an owned illustration, where one exists. Presentation-only:
/// does not change matching logic, card identity, or level data. Falls back
/// to the emoji text for anything not in this table, so every level keeps
/// working regardless of how much of the theme art exists yet.
const Map<String, MiMemoryAnimal> miMemoryAnimalByEmoji = {
  '🐱': MiMemoryAnimal.cat,
  '🐶': MiMemoryAnimal.dog,
  '🐟': MiMemoryAnimal.fish,
  '🐦': MiMemoryAnimal.bird,
};

/// Renders one Animals-theme illustration.
class MiMemoryCardArt extends StatelessWidget {
  const MiMemoryCardArt(this.animal, {super.key, this.size = 64});

  final MiMemoryAnimal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path =
        'packages/design_system/assets/memory-cards/animals/game_memory_animals_${animal.name}_v01.svg';
    return SvgPicture.asset(path, width: size, height: size);
  }
}

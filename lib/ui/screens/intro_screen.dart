import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _nameController = TextEditingController();
  int _selectedClassIndex = 0; // 0: Warrior, 1: Sorcerer, 2: Assassin

  final List<Map<String, dynamic>> _classes = [
    {
      'name': 'WARRIOR',
      'icon': Icons.shield_outlined,
      'image': 'assets/images/class_warrior.jpg',
      'initiative': 'IV',
      'vitality': 'XII',
    },
    {
      'name': 'SORCERER',
      'icon': Icons.menu_book_outlined,
      'image': 'assets/images/class_sorcerer.jpg',
      'initiative': 'III',
      'vitality': 'VIII',
    },
    {
      'name': 'ASSASSIN',
      'icon': Icons.colorize_outlined, // Dagger-like icon
      'image': 'assets/images/class_assassin.jpg',
      'initiative': 'VI',
      'vitality': 'X',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _commenceChronicle() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'UNSCRIBED IDENTITY',
        'Please scribe thy name to begin the chronicle.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF220A0A),
        colorText: const Color(0xFFFFAAAA),
        borderRadius: 0,
        borderColor: VitruvianColors.rustBlood,
        borderWidth: 1.0,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final playerState = Get.find<PlayerState>();
    playerState.initializeCustomCharacter(name, _selectedClassIndex);
  }

  @override
  Widget build(BuildContext context) {
    final activeClass = _classes[_selectedClassIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0C0A08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0A08),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, color: VitruvianColors.sepiaUmber, size: 20),
            const SizedBox(width: 10),
            Text(
              'VITRUVIAN SHADOW',
              style: VitruvianTypography.serifTitle(
                fontSize: 18,
                color: VitruvianColors.agedBone,
              ).copyWith(letterSpacing: 1.5),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF2A2218), height: 1.0),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SCRIBE THY NAME Section
              Text(
                'SCRIBE THY NAME',
                style: VitruvianTypography.serifTitle(
                  fontSize: 14,
                  color: const Color(0xFF8A7A68),
                ).copyWith(letterSpacing: 2.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0C0A),
                  border: Border.all(color: const Color(0xFF2A2218), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _nameController,
                  cursorColor: VitruvianColors.sepiaUmber,
                  style: VitruvianTypography.serifBody(
                    fontSize: 16,
                    color: VitruvianColors.agedBone,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '...',
                    hintStyle: VitruvianTypography.serifBody(
                      fontSize: 16,
                      color: const Color(0xFF4A3E34),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // CHOOSE THY PATH Section (moved above the image)
              Text(
                'CHOOSE THY PATH',
                style: VitruvianTypography.serifTitle(
                  fontSize: 14,
                  color: const Color(0xFF8A7A68),
                ).copyWith(letterSpacing: 2.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Tabs row: Warrior, Sorcerer, Assassin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_classes.length, (index) {
                  final cls = _classes[index];
                  final isSelected = _selectedClassIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedClassIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1C1410) : const Color(0xFF0E0C0A),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8A7A68) : const Color(0xFF2A2218),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cls['icon'],
                                color: isSelected ? const Color(0xFFE0C8B0) : const Color(0xFF5A4E44),
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cls['name'],
                                style: VitruvianTypography.serifTitle(
                                  fontSize: 10,
                                  color: isSelected ? const Color(0xFFE0C8B0) : const Color(0xFF5A4E44),
                                ).copyWith(letterSpacing: 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Class Image preview (using the uploaded class artworks)
              EtchedContainer(
                padding: EdgeInsets.zero,
                borderColor: const Color(0xFF2A2218),
                backgroundColor: const Color(0xFF0C0A08),
                child: Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(activeClass['image']),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row block
              _buildStatRow('INITIATIVE', activeClass['initiative']),
              const SizedBox(height: 12),
              _buildStatRow('VITALITY', activeClass['vitality']),
              const SizedBox(height: 36),

              // Commence Chronicle red button
              InkWell(
                onTap: _commenceChronicle,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    color: VitruvianColors.rustBlood,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'COMMENCE CHRONICLE',
                    style: VitruvianTypography.serifTitle(
                      fontSize: 14,
                      color: VitruvianColors.agedBone,
                      fontWeight: FontWeight.bold,
                    ).copyWith(letterSpacing: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String romanValue) {
    return Row(
      children: [
        Text(
          label,
          style: VitruvianTypography.serifBody(
            fontSize: 14,
            color: const Color(0xFF8A7A68),
          ).copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dotCount = (constraints.maxWidth / 5).floor();
              return Text(
                '.' * dotCount,
                style: const TextStyle(color: Color(0xFF2A2218), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.clip,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          romanValue,
          style: VitruvianTypography.serifTitle(
            fontSize: 14,
            color: const Color(0xFFE0C8B0),
          ),
        ),
      ],
    );
  }
}

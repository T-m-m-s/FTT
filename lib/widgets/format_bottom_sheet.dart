import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/library_entry.dart';
import '../theme/app_colors.dart';

class FormatBottomSheet extends StatefulWidget {
  final LibraryEntry entry;
  final Function(LibraryEntry) onSave;

  const FormatBottomSheet({
    super.key,
    required this.entry,
    required this.onSave,
  });

  @override
  State<FormatBottomSheet> createState() => _FormatBottomSheetState();
}

class _FormatBottomSheetState extends State<FormatBottomSheet> {
  late String _platform;
  late String _format;
  late bool _isOwned;
  late TextEditingController _priceController;
  DateTime? _purchaseDate;

  final List<String> gamePlatforms = [
    'PC',
    'PlayStation 5',
    'Xbox Series X',
    'Nintendo Switch',
    'Steam Deck',
  ];

  final List<String> cinemaPlatforms = [
    'Netflix',
    'Apple TV+',
    'Prime Video',
    'Disney+',
    'Max',
    'Cinema / Theater',
    '4K UHD Blu-ray',
  ];

  final List<String> gameFormats = [
    'Steam',
    'GOG',
    'Epic Games',
    'Digital',
    'Physical',
    'Subscription',
  ];

  final List<String> cinemaFormats = [
    'Streaming',
    'Digital Purchase',
    'Rental',
    'Theater Ticket',
    '4K Blu-ray',
    'Physical Disc',
  ];

  @override
  void initState() {
    super.initState();
    _platform = widget.entry.platform;
    _format = widget.entry.format;
    _isOwned = widget.entry.isOwned;
    _priceController = TextEditingController(
      text: widget.entry.pricePaid != null ? widget.entry.pricePaid!.toStringAsFixed(2) : '',
    );
    _purchaseDate = widget.entry.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGame = widget.entry.mediaItem.mediaType.name == 'game';
    final platformList = isGame ? gamePlatforms : cinemaPlatforms;
    final formatList = isGame ? gameFormats : cinemaFormats;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Cancel and Save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Text(
                  'Platforms & Formats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.entry.platform = _platform;
                    widget.entry.format = _format;
                    widget.entry.isOwned = _isOwned;
                    widget.entry.pricePaid = double.tryParse(_priceController.text);
                    widget.entry.purchaseDate = _purchaseDate;
                    widget.onSave(widget.entry);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Platforms Chips
            const Text(
              'Platforms',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: platformList.map((plat) {
                final isSelected = _platform.contains(plat) || _platform == plat;
                return ChoiceChip(
                  label: Text(plat),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _platform = plat);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Formats Chips
            const Text(
              'Format / Store',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formatList.map((fmt) {
                final isSelected = _format == fmt;
                return ChoiceChip(
                  label: Text(fmt),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _format = fmt);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Owned Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Owned in Library',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isOwned,
                    activeThumbColor: AppColors.primaryLight,
                    activeTrackColor: AppColors.primaryDark,
                    onChanged: (val) => setState(() => _isOwned = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price Paid & Purchase Date Rows
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price Paid (USD)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Purchase Date',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.surfaceElevated,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _purchaseDate = picked);
                            }
                          },
                          child: Text(
                            _purchaseDate != null
                                ? DateFormat('MMM d, yyyy').format(_purchaseDate!)
                                : 'Select date',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}

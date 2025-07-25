import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common_widget/common_button.dart';
import '../constants.dart';
import '../theme.dart';

/// Represents a selectable price range with optional minimum and maximum values.
class PriceRange {
  final double? min;
  final double? max;
  final String label;

  const PriceRange({this.min, this.max, required this.label});
}

/// Predefined stake ranges used by the filter modal.
const List<PriceRange> kPriceRanges = [
  PriceRange(min: 0, max: 10, label: '₹0-10'),
  PriceRange(min: 10, max: 50, label: '₹10-50'),
  PriceRange(min: 51, max: 99, label: '₹51-99'),
  PriceRange(min: 100, max: null, label: '₹100+'),
];

/// Displays a bottom sheet allowing users to pick a price range.
Future<PriceRange?> showPriceFilterModal(BuildContext context) {
  return showModalBottomSheet<PriceRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      int? selectedIndex;
      return SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: AppGradients.blueVertical,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: AppColors.brandYellowColor.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Entry Fee',
                      style: AppTextStyles.poppinsSemiBold.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: List.generate(kPriceRanges.length, (i) {
                        final range = kPriceRanges[i];
                        final selected = selectedIndex == i;
                        return SizedBox(
                          width: 90.w,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary.withOpacity(selected ? 0.2 : 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.gold
                                    : Colors.white24,
                              ),
                            ),
                            onPressed: () => setState(() => selectedIndex = i),
                            child: Text(range.label),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: CommonButton(
                            onPressed: () => Navigator.pop(ctx),
                            btnChild: Text(
                              'Cancel',
                              style: AppTextStyles.poppinsSemiBold.copyWith(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: CommonButton(
                            onPressed: selectedIndex == null
                                ? null
                                : () => Navigator.pop(
                                    ctx, kPriceRanges[selectedIndex!]),
                            btnChild: Text(
                              'Apply',
                              style: AppTextStyles.poppinsSemiBold.copyWith(
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}


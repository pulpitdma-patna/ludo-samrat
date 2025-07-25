import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';
import '../constants.dart';
import 'app_card.dart';

/// Reusable card widget to display game information like entry fee,
/// prize and joined count.
class GameCard extends StatelessWidget {
  /// Title widget shown at the start of the card header.
  final Widget title;

  /// Amount user must pay to participate.
  final double entryFee;

  /// Prize or pot amount for the game.
  final double prize;

  /// Number of players already joined.
  final int? joined;

  /// Maximum number of seats available.
  final int? seatLimit;

  /// Text describing the bracket or other primary info.
  final String? bracketInfo;

  /// Optional secondary information line.
  final String? secondaryInfo;

  /// Optional extra info shown next to the bracket line, e.g. discount.
  final String? extraInfo;

  /// Optional tournament start time display.
  final String? startTime;

  /// Indicator of how full the tournament is, between 0 and 1.
  final double? progress;

  /// Displayed on the action button.
  final String actionText;

  /// Callback when the action button is tapped.
  final VoidCallback? onAction;

  /// Whether the action button should be enabled.
  final bool actionEnabled;

  /// Text shown as a small badge in the top row.
  final String? statusText;

  /// Color of the status badge background.
  final Color? statusColor;

  /// Background color of the card.
  final Color? backgroundColor;


  /// Border around the card container.
  final BoxBorder? border;

  /// Shadow around the card container.
  final List<BoxShadow>? boxShadow;

  /// Optional gradient background for the card.
  final Gradient? gradient;

  const GameCard({
    super.key,
    required this.title,
    required this.entryFee,
    required this.prize,
    this.joined,
    this.seatLimit,
    this.bracketInfo,
    this.secondaryInfo,
    this.extraInfo,
    this.startTime,
    this.progress,
    this.actionText = 'Join',
    this.onAction,
    this.actionEnabled = true,
    this.statusText,
    this.statusColor,
    this.backgroundColor,
    this.border =
        const Border.fromBorderSide(BorderSide(color: Color(0x4DD4AF37))),
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final joinedText =
        (joined != null && seatLimit != null) ? '$joined/$seatLimit joined' : null;
    final progressValue = progress?.clamp(0.0, 1.0);
    final semanticsLabel =
        'game with entry fee \u20b9${entryFee.toStringAsFixed(0)} and prize \u20b9${prize.toStringAsFixed(0)}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: AppCard(

        backgroundColor:
            gradient == null ? (backgroundColor ?? Theme.of(context).cardColor) : null,
        backgroundGradient: gradient ?? AppGradients.blueVertical,
        border:
            border ?? Border.all(color: AppColors.brandYellowColor.withOpacity(0.3)),

        boxShadow: boxShadow,
        header: CardHeader(
          title: DefaultTextStyle.merge(
            style: AppTextStyles.poppinsSemiBold.copyWith(
              fontSize: 16.sp,
              color: AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
            child: title,
          ),
          center: bracketInfo != null
              ? Text(
                  bracketInfo!,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppinsRegular.copyWith(
                    fontSize: 14.sp,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                )
              : null,
          actions: [
            if (statusText != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor ?? Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  statusText!,
                  style: AppTextStyles.poppinsRegular.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
      ),
      body: CardBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (extraInfo != null) ...[
              SizedBox(height: 4.h),
              Text(
                extraInfo!,
                style: AppTextStyles.poppinsRegular.copyWith(
                  fontSize: 14.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (startTime != null) ...[
              SizedBox(height: 4.h),
              Text(
                startTime!,
                style: AppTextStyles.poppinsRegular.copyWith(
                  fontSize: 12.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (secondaryInfo != null) ...[
              SizedBox(height: 4.h),
              Text(
                secondaryInfo!,
                style: AppTextStyles.poppinsRegular.copyWith(
                  fontSize: 14.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Prize: \u20b9${prize.toStringAsFixed(0)}',
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.brandYellowColor,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Entry: \u20b9${entryFee.toStringAsFixed(0)}',
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.brandYellowColor,
                    ),
                  ),
                ),
                if (joinedText != null) ...[
                  SizedBox(width: 12.w),
                  Text(
                    joinedText,
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: 12.sp,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const Spacer(),
                Semantics(
                  label: 'game card action',
                  button: true,
                  child: ElevatedButton(
                    onPressed: actionEnabled ? onAction : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.horizontal.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: AppTextStyles.poppinsSemiBold.copyWith(
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (progressValue != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progressValue,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      minHeight: 6.h,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${(progressValue * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.poppinsRegular.copyWith(
                      fontSize: 12.sp,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ],
      ),
      ),
      footer: null,
      ),
    );
    }
}


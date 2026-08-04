import 'package:freezed_annotation/freezed_annotation.dart';

part 'bonus_rule.freezed.dart';
part 'bonus_rule.g.dart';

/// Maps 1:1 to `public.bonus_rules`.
@freezed
class BonusRule with _$BonusRule {
  const factory BonusRule({
    required String id,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'buy_quantity') required int buyQuantity,
    @JsonKey(name: 'free_quantity') required int freeQuantity,
    @JsonKey(name: 'is_stackable') @Default(true) bool isStackable,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _BonusRule;

  const BonusRule._();

  factory BonusRule.fromJson(Map<String, dynamic> json) =>
      _$BonusRuleFromJson(json);
}

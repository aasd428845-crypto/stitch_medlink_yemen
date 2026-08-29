import 'package:freezed_annotation/freezed_annotation.dart';

part 'special_request.freezed.dart';
part 'special_request.g.dart';

/// Maps 1:1 to `public.special_requests`.
@freezed
class SpecialRequest with _$SpecialRequest {
  const factory SpecialRequest({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    @JsonKey(name: 'product_name') required String productName,
    @Default(1) int quantity,
    String? notes,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _SpecialRequest;

  const SpecialRequest._();

  factory SpecialRequest.fromJson(Map<String, dynamic> json) =>
      _$SpecialRequestFromJson(json);
}

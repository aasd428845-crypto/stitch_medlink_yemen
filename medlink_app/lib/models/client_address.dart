import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_address.freezed.dart';
part 'client_address.g.dart';

/// Maps 1:1 to `public.client_addresses`.
@freezed
class ClientAddress with _$ClientAddress {
  const factory ClientAddress({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    required String label,
    @JsonKey(name: 'address_text') required String addressText,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _ClientAddress;

  const ClientAddress._();

  factory ClientAddress.fromJson(Map<String, dynamic> json) =>
      _$ClientAddressFromJson(json);
}

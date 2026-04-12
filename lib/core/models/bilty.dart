import 'package:equatable/equatable.dart';

enum PaymentType { toPay, paid, toBeBilled }
enum BiltyStatus  { pending, loadedInChallan, dispatched, delivered }

class PaymentTypeHelper {
  static const Map<PaymentType, String> _labels = {
    PaymentType.toPay:      'To Pay',
    PaymentType.paid:       'Paid',
    PaymentType.toBeBilled: 'To Be Billed',
  };
  static String label(PaymentType t) => _labels[t]!;
}

class BiltyStatusHelper {
  static const Map<BiltyStatus, String> _labels = {
    BiltyStatus.pending:         'Pending',
    BiltyStatus.loadedInChallan: 'In Challan',
    BiltyStatus.dispatched:      'Dispatched',
    BiltyStatus.delivered:       'Delivered',
  };
  static String label(BiltyStatus s) => _labels[s]!;
}

class Bilty extends Equatable {
  final String id;
  final String userId;
  final String biltyNo;
  final String routeId;
  final String consignorName;
  final String consignorPhone;
  final String consignorGst;       // NEW: GST number
  final String consigneeName;
  final String consigneePhone;
  final String consigneeGst;       // NEW: GST number
  final String consigneeCity;
  final String goodsDescription;
  final String goodsCategory;
  final double weightKg;
  final int noOfPackages;
  final double freightPerKg;
  final PaymentType paymentType;
  final BiltyStatus status;
  final String? challanId;
  final DateTime createdAt;
  final String createdBy;

  const Bilty({
    required this.id,
    required this.userId,
    required this.biltyNo,
    required this.routeId,
    required this.consignorName,
    required this.consignorPhone,
    this.consignorGst = '',
    required this.consigneeName,
    required this.consigneePhone,
    this.consigneeGst = '',
    required this.consigneeCity,
    required this.goodsDescription,
    required this.goodsCategory,
    required this.weightKg,
    required this.noOfPackages,
    required this.freightPerKg,
    required this.paymentType,
    this.status = BiltyStatus.pending,
    this.challanId,
    required this.createdAt,
    required this.createdBy,
  });

  double get baseFreight  => weightKg * freightPerKg;
  double get gst          => baseFreight * 0.18;
  double get totalFreight => baseFreight + gst;
  double get weightMT     => weightKg / 1000;
  bool   get isPending    => status == BiltyStatus.pending;

  Bilty copyWith({
    BiltyStatus? status,
    String? challanId,
    double? freightPerKg,
  }) {
    return Bilty(
      id: id, userId: userId, biltyNo: biltyNo, routeId: routeId,
      consignorName: consignorName, consignorPhone: consignorPhone, consignorGst: consignorGst,
      consigneeName: consigneeName, consigneePhone: consigneePhone, consigneeGst: consigneeGst,
      consigneeCity: consigneeCity, goodsDescription: goodsDescription,
      goodsCategory: goodsCategory, weightKg: weightKg,
      noOfPackages: noOfPackages,
      freightPerKg: freightPerKg ?? this.freightPerKg,
      paymentType: paymentType,
      status:    status    ?? this.status,
      challanId: challanId ?? this.challanId,
      createdAt: createdAt, createdBy: createdBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'biltyNo': biltyNo, 'routeId': routeId,
    'consignorName': consignorName, 'consignorPhone': consignorPhone, 'consignorGst': consignorGst,
    'consigneeName': consigneeName, 'consigneePhone': consigneePhone, 'consigneeGst': consigneeGst,
    'consigneeCity': consigneeCity, 'goodsDescription': goodsDescription,
    'goodsCategory': goodsCategory, 'weightKg': weightKg,
    'noOfPackages': noOfPackages, 'freightPerKg': freightPerKg,
    'paymentType': paymentType.index, 'status': status.index,
    'challanId': challanId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'createdBy': createdBy,
  };

  factory Bilty.fromMap(Map<String, dynamic> m) => Bilty(
    id: m['id'], userId: m['userId'] ?? '', biltyNo: m['biltyNo'], routeId: m['routeId'],
    consignorName: m['consignorName'], consignorPhone: m['consignorPhone'],
    consignorGst: m['consignorGst'] ?? '',
    consigneeName: m['consigneeName'], consigneePhone: m['consigneePhone'],
    consigneeGst: m['consigneeGst'] ?? '',
    consigneeCity: m['consigneeCity'], goodsDescription: m['goodsDescription'],
    goodsCategory: m['goodsCategory'],
    weightKg:     (m['weightKg']     as num).toDouble(),
    noOfPackages:  m['noOfPackages'],
    freightPerKg: (m['freightPerKg'] as num).toDouble(),
    paymentType: PaymentType.values[m['paymentType'] ?? 0],
    status:      BiltyStatus.values[m['status']      ?? 0],
    challanId:   m['challanId'],
    createdAt:   DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
    createdBy:   m['createdBy'] ?? '',
  );

  @override
  List<Object?> get props => [id, biltyNo, status, challanId];
}

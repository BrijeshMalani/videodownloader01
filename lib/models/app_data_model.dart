class AppDataModel {
  final String id;
  final String acId;
  final String name;
  final String pkgName;
  final String isLive;
  final String appId;
  final String admobId;
  final String admobId1;
  final String admobId2;
  final String createdDate;
  final String admobFull;
  final String admobFull1;
  final String admobFull2;
  final String admobNative;
  final String admobNative1;
  final String admobNative2;
  final String rewardedInt;
  final String rewardedInt1;
  final String rewardedInt2;
  final String rewardedFull;
  final String rewardedFull1;
  final String rewardedFull2;
  final String gamezopId;
  final String qurekaId;
  final String fbId;
  final String fbFull;
  final String fbNative;
  final String startAppId;
  final String startAppFull;
  final String startAppNative;
  final String startAppRewarded;
  final String adType;
  final String appLogoName;

  AppDataModel({
    required this.id,
    required this.acId,
    required this.name,
    required this.pkgName,
    required this.isLive,
    required this.appId,
    required this.admobId,
    required this.admobId1,
    required this.admobId2,
    required this.createdDate,
    required this.admobFull,
    required this.admobFull1,
    required this.admobFull2,
    required this.admobNative,
    required this.admobNative1,
    required this.admobNative2,
    required this.rewardedInt,
    required this.rewardedInt1,
    required this.rewardedInt2,
    required this.rewardedFull,
    required this.rewardedFull1,
    required this.rewardedFull2,
    required this.gamezopId,
    required this.qurekaId,
    required this.fbId,
    required this.fbFull,
    required this.fbNative,
    required this.startAppId,
    required this.startAppFull,
    required this.startAppNative,
    required this.startAppRewarded,
    required this.adType,
    required this.appLogoName,
  });

  factory AppDataModel.fromJson(Map<String, dynamic> json) {
    return AppDataModel(
      id: json['id'] ?? '',
      acId: json['ac_id'] ?? '',
      name: json['name'] ?? '',
      pkgName: json['pkgname'] ?? '',
      isLive: json['islive'] ?? '',
      appId: json['appid'] ?? '',
      admobId: json['admobid'] ?? '',
      admobId1: json['admobid1'] ?? '',
      admobId2: json['admobid2'] ?? '',
      createdDate: json['created_date'] ?? '',
      admobFull: json['admobfull'] ?? '',
      admobFull1: json['admobfull1'] ?? '',
      admobFull2: json['admobfull2'] ?? '',
      admobNative: json['admobnative'] ?? '',
      admobNative1: json['admobnative1'] ?? '',
      admobNative2: json['admobnative2'] ?? '',
      rewardedInt: json['rewardedint'] ?? '',
      rewardedInt1: json['rewardedint1'] ?? '',
      rewardedInt2: json['rewardedint2'] ?? '',
      rewardedFull: json['rewardedfull'] ?? '',
      rewardedFull1: json['rewardedfull1'] ?? '',
      rewardedFull2: json['rewardedfull2'] ?? '',
      gamezopId: json['gamezopid'] ?? '',
      qurekaId: json['qurekaid'] ?? '',
      fbId: json['fbid'] ?? '',
      fbFull: json['fbfull'] ?? '',
      fbNative: json['fbnative'] ?? '',
      startAppId: json['startappid'] ?? '',
      startAppFull: json['startappfull'] ?? '',
      startAppNative: json['startappnative'] ?? '',
      startAppRewarded: json['startapprewarded'] ?? '',
      adType: json['adtype'] ?? '',
      appLogoName: json['applogoname'] ?? '',
    );
  }

  @override
  String toString() {
    return 'AppDataModel(\n'
        '  id: $id\n'
        '  name: $name\n'
        '  pkgName: $pkgName\n'
        '  appId: $appId\n'
        '  admobId: $admobId\n'
        '  admobFull: $admobFull\n'
        '  admobNative: $admobNative\n'
        '  admobFull1: $admobFull1\n'
        '  rewardedFull: $rewardedFull\n'
        '  rewardedFull2: $rewardedFull2\n'
        ')';
  }
}

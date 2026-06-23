// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Bản đồ Việt Nam';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get map => 'Bản đồ';

  @override
  String get weather => 'Thời tiết';

  @override
  String get campaigns => 'Chiến dịch';

  @override
  String get campaign => 'Chiến dịch';

  @override
  String get events => 'Sự kiện';

  @override
  String get schools => 'Trường học';

  @override
  String get school => 'Trường học';

  @override
  String get users => 'Người dùng';

  @override
  String get mine => 'Của tôi';

  @override
  String get dashboard => 'Bảng điều khiển';

  @override
  String get accessDenied => 'Truy cập bị từ chối';

  @override
  String get noPermission => 'Bạn không có quyền xem trang này.';

  @override
  String get signInToContinue => 'Đăng nhập để tiếp tục với vai trò được gán';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get signingIn => 'Đang đăng nhập...';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get refresh => 'Làm mới';

  @override
  String get retry => 'Thử lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get create => 'Tạo';

  @override
  String get apply => 'Áp dụng';

  @override
  String get clear => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get assign => 'Gán';

  @override
  String get remove => 'Gỡ';

  @override
  String get submit => 'Gửi';

  @override
  String get submitRegistration => 'Gửi đăng ký';

  @override
  String get submitting => 'Đang gửi...';

  @override
  String get required => 'Bắt buộc';

  @override
  String get all => 'Tất cả';

  @override
  String get previous => 'Trước';

  @override
  String get next => 'Sau';

  @override
  String page(int page, int total) {
    return 'Trang $page / $total';
  }

  @override
  String showingOf(int count, int total) {
    return 'Hiển thị $count trong $total';
  }

  @override
  String get noCampaignsYet => 'Chưa có chiến dịch';

  @override
  String get noEventsYet => 'Chưa có sự kiện';

  @override
  String get noSchoolsFound => 'Không tìm thấy trường học';

  @override
  String get noStudents => 'Không có học sinh';

  @override
  String get noTeachersPersons => 'Không có giáo viên/nhân sự';

  @override
  String get noRelatives => 'Không có người thân';

  @override
  String get noEmployees => 'Không có nhân viên';

  @override
  String get noRegistrationsYet => 'Chưa có đăng ký';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get campaignCreated => 'Chiến dịch đã được tạo';

  @override
  String get campaignSaved => 'Đã lưu chiến dịch';

  @override
  String get eventSaved => 'Đã lưu sự kiện';

  @override
  String get schoolAssigned => 'Đã gán trường';

  @override
  String get schoolRemoved => 'Đã gỡ trường';

  @override
  String get employeeAssigned => 'Đã gán nhân viên';

  @override
  String get employeeRemoved => 'Đã gỡ nhân viên';

  @override
  String get registrationSubmitted => 'Đã gửi đăng ký';

  @override
  String get campaignDashboard => 'Bảng điều khiển chiến dịch';

  @override
  String get campaignEvents => 'Sự kiện của chiến dịch';

  @override
  String get createEvent => 'Tạo sự kiện';

  @override
  String get eventDetail => 'Chi tiết sự kiện';

  @override
  String get thongTin => 'Thông tin';

  @override
  String get truongThamGia => 'Trường tham gia';

  @override
  String get nhanSu => 'Nhân sự';

  @override
  String get interactions => 'Tương tác';

  @override
  String get assignedSchools => 'Trường đã gán';

  @override
  String get findSchools => 'Tìm trường học';

  @override
  String get assignedEmployees => 'Nhân viên đã gán';

  @override
  String get employees => 'Nhân viên';

  @override
  String get noAssignedSchools => 'Chưa gán trường nào';

  @override
  String get noAssignedEmployees => 'Chưa gán nhân viên nào';

  @override
  String get schoolDetail => 'Chi tiết trường học';

  @override
  String get tongQuan => 'Tổng quan';

  @override
  String get hocSinh => 'Học sinh';

  @override
  String get gvBgh => 'GV/BGH';

  @override
  String get nguoiThan => 'Người thân';

  @override
  String get province => 'Tỉnh/Thành phố';

  @override
  String get provinceCode => 'Mã tỉnh';

  @override
  String get commune => 'Xã/Phường';

  @override
  String get communeCode => 'Mã xã';

  @override
  String get schoolCode => 'Mã trường';

  @override
  String get address => 'Địa chỉ';

  @override
  String get area => 'Khu vực';

  @override
  String get name => 'Tên';

  @override
  String get type => 'Loại';

  @override
  String get status => 'Trạng thái';

  @override
  String get location => 'Địa điểm';

  @override
  String get note => 'Ghi chú';

  @override
  String get grade => 'Khối lớp';

  @override
  String get classLabel => 'Lớp';

  @override
  String get phone => 'Điện thoại';

  @override
  String get role => 'Vai trò';

  @override
  String get start => 'Bắt đầu';

  @override
  String get end => 'Kết thúc';

  @override
  String get owner => 'Người phụ trách';

  @override
  String get time => 'Thời gian';

  @override
  String get startsAt => 'Bắt đầu lúc';

  @override
  String get endsAt => 'Kết thúc lúc';

  @override
  String get viewOnFullMap => 'Xem trên bản đồ đầy đủ';

  @override
  String get createEventTitle => 'Tạo sự kiện';

  @override
  String get editEventTitle => 'Sửa sự kiện';

  @override
  String get eventType => 'Loại sự kiện';

  @override
  String get locationLabel => 'Nhãn địa điểm';

  @override
  String get pickOnMap => 'Chọn trên bản đồ';

  @override
  String get noLocationSelected => 'Chưa chọn vị trí';

  @override
  String get noSchoolsAssigned =>
      'Chưa gán trường nào. Hãy gán trường trong tab Trường để bật tự động định vị, hoặc đánh dấu vị trí thủ công bên dưới.';

  @override
  String get provinceCenterLocation =>
      'Đang sử dụng tâm tỉnh làm vị trí gần đúng - kéo điểm đánh dấu để điều chỉnh.';

  @override
  String get endsAtMustBeAfterStartsAt =>
      'Thời gian kết thúc phải sau thời gian bắt đầu';

  @override
  String get useYyyyMmDdTHhMmSs => 'Sử dụng định dạng yyyy-MM-ddTHH:mm:ss';

  @override
  String get campaignRegistration => 'Đăng ký chiến dịch';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get schoolUid => 'Mã trường';

  @override
  String get registration => 'Đăng ký';

  @override
  String get myRegistrations => 'Đăng ký của tôi';

  @override
  String get minimum8Characters => 'Tối thiểu 8 ký tự';

  @override
  String get kpiEvents => 'Sự kiện';

  @override
  String get kpiSchools => 'Trường học';

  @override
  String get kpiEmployees => 'Nhân viên';

  @override
  String get kpiInteractions => 'Tương tác';

  @override
  String get interactionsByOutcome => 'Tương tác theo kết quả';

  @override
  String get interactionsByProvince => 'Tương tác theo tỉnh';

  @override
  String get topSchools => 'Trường học hàng đầu';

  @override
  String get studentRegistrations => 'Đăng ký học sinh';

  @override
  String get outcome => 'Kết quả';

  @override
  String get total => 'Tổng';

  @override
  String get schoolUidLabel => 'Mã trường';

  @override
  String get loadingWeather => 'Đang tải thời tiết...';

  @override
  String weatherUpdatedAt(String time) {
    return 'Cập nhật lúc: $time';
  }

  @override
  String feelsLike(String temp) {
    return 'Cảm giác như $temp°C';
  }

  @override
  String get humidity => 'Độ ẩm';

  @override
  String get wind => 'Gió';

  @override
  String get pressure => 'Áp suất';

  @override
  String get visibility => 'Tầm nhìn';

  @override
  String get cachedData => 'Dữ liệu cache';

  @override
  String get weatherTitle => 'Thời tiết';

  @override
  String get kV1 => 'KV1';

  @override
  String get kV2 => 'KV2';

  @override
  String get kV2Nt => 'KV2_NT';

  @override
  String get kV3 => 'KV3';

  @override
  String get campaignsTitle => 'Danh sách chiến dịch';

  @override
  String get createCampaign => 'Tạo chiến dịch';

  @override
  String get searchCampaigns => 'Tìm kiếm chiến dịch';

  @override
  String get allStatuses => 'Tất cả';

  @override
  String get errorLoadingCampaigns => 'Lỗi khi tải chiến dịch';

  @override
  String get campaignName => 'Tên chiến dịch';

  @override
  String get campaignObjective => 'Mục tiêu chiến dịch';

  @override
  String get campaignStartDate => 'Ngày bắt đầu';

  @override
  String get campaignEndDate => 'Ngày kết thúc';

  @override
  String get createCampaignTitle => 'Tạo chiến dịch mới';

  @override
  String get editCampaignTitle => 'Sửa chiến dịch';

  @override
  String get saving => 'Đang lưu...';

  @override
  String get archive => 'Lưu trữ';

  @override
  String get archived => 'Đã lưu trữ';

  @override
  String get unarchive => 'Khôi phục';

  @override
  String get confirmDelete => 'Xác nhận xóa';

  @override
  String get confirmArchive => 'Xác nhận lưu trữ';

  @override
  String get confirmUnarchive => 'Xác nhận khôi phục';
}

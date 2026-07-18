# Attendance (Chấm công) — FE Implementation Guide

**Backend status:** done, merged vào `Loc` (`BE/src/main/java/com/vnmap/attendance/`).
**Base URL:** `/api/v1/attendance` (dùng chung `AppConfig.baseUrl` + `DioClient` hiện có).
**Auth:** Bearer JWT như mọi API khác. Backend tự suy ra `employeeId` của người gọi từ token — FE **không** cần gửi employeeId khi tự check-in/out.
**Gắn với campaign:** Check-in **bắt buộc** phải chọn 1 campaign đang `ACTIVE` (chiến dịch "đang mở"); có thể chọn thêm 1 event cụ thể trong campaign đó (tuỳ chọn). Không cho check-in nếu không có campaign nào đang mở.

---

## 1. Ma trận quyền

| Role | Được làm gì |
|---|---|
| STAFF | Tự check-in/check-out (phải chọn campaign đang mở). Xem lịch sử của chính mình. |
| MANAGER | Như STAFF, **cộng thêm**: xem danh sách/chi tiết của mọi nhân viên, tạo bản ghi thủ công, sửa (correction), xoá bản ghi. |
| ADMIN | Như MANAGER: xem, tạo thủ công, sửa, xoá mọi bản ghi (full CRUD — không còn read-only). |
| STUDENT | Không thấy tính năng này. |

Người dùng chưa liên kết hồ sơ nhân viên (`employeeId == null`) sẽ nhận `400 Bad Request` khi check-in/out → hiển thị "Tài khoản của bạn chưa được liên kết với hồ sơ nhân viên."

Check-in/check-out **không** có luồng "chờ duyệt" — bản ghi được tạo ngay lập tức và MANAGER/ADMIN có thể sửa/xoá bất cứ lúc nào nếu sai. Khi staff check-in hoặc check-out, tất cả MANAGER và ADMIN đang active sẽ nhận push notification (loại `STAFF_CHECKED_IN` / `STAFF_CHECKED_OUT`).

---

## 2. API Contract

| Method | Path | Role | Body / Query | Ghi chú |
|---|---|---|---|---|
| POST | `/attendance/check-in` | STAFF, MANAGER | `{ campaignId, eventId?, note?, lat?, lng? }` | `campaignId` **bắt buộc**. 409 nếu campaign không `ACTIVE`, 409 nếu đã có phiên đang mở, 404 nếu campaign không tồn tại, 400 nếu `eventId` không thuộc `campaignId`. |
| POST | `/attendance/check-out` | STAFF, MANAGER | `{ note?, lat?, lng? }` | Đóng phiên đang mở (kế thừa campaign/event từ lúc check-in). 409 nếu không có phiên đang mở. |
| POST | `/attendance` | MANAGER, ADMIN | `{ employeeId, campaignId, eventId?, checkInAt?, checkOutAt?, checkInNote?, checkOutNote? }` | Tạo bản ghi thủ công cho 1 nhân viên (vd quên check-in). `checkInAt` mặc định = now nếu bỏ qua. Có `checkOutAt` → tạo bản ghi đã `CLOSED` luôn. |
| GET | `/attendance/me` | STAFF, MANAGER | `?page=0&limit=20` | Lịch sử của chính mình, mới nhất trước. |
| GET | `/attendance` | MANAGER, ADMIN | `?employeeId=&status=&from=&to=&page=&limit=` | `status`: `OPEN`/`CLOSED`. `from`/`to`: ISO `LocalDateTime`, vd `2026-07-01T00:00:00`. |
| GET | `/attendance/{id}` | MANAGER, ADMIN | — | Chi tiết 1 bản ghi. |
| PUT | `/attendance/{id}` | MANAGER, ADMIN | `{ campaignId?, eventId?, checkInAt?, checkOutAt?, checkInNote?, checkOutNote? }` | Field nào `null`/bỏ qua thì giữ nguyên giá trị cũ. Set `checkOutAt` sẽ đóng phiên (status→CLOSED). |
| DELETE | `/attendance/{id}` | MANAGER, ADMIN | — | Xoá bản ghi sai/trùng. |

Mọi response đều bọc trong envelope chuẩn `{ success, message, data, timestamp }` — giống hệt các API khác trong app.

### `AttendanceDto`

```json
{
  "id": 10,
  "employeeId": 5,
  "employeeName": "Nguyen Van A",
  "campaignId": 1,
  "campaignName": "Spring Drive",
  "eventId": null,
  "eventName": null,
  "checkInAt": "2026-07-18T08:00:00",
  "checkOutAt": "2026-07-18T17:00:00",
  "checkInNote": "string | null",
  "checkOutNote": "string | null",
  "checkInLat": 10.77, "checkInLng": 106.7,
  "checkOutLat": 10.77, "checkOutLng": 106.7,
  "status": "OPEN | CLOSED",
  "workedMinutes": 540
}
```
`workedMinutes` là `null` khi phiên còn `OPEN`. `campaignId`/`campaignName` có thể `null` chỉ với các bản ghi cũ tạo trước khi tính năng gắn campaign được thêm vào.

FE cần 1 dropdown "chọn campaign đang mở" trước khi bấm Check-in — gọi `GET /api/v1/campaigns?status=ACTIVE` (hoặc filter phía client) để lấy danh sách. Nếu không có campaign nào `ACTIVE`, ẩn/disable nút Check-in và hiển thị thông báo "Hiện không có chiến dịch nào đang mở".

### Danh sách (`PagedResponse<AttendanceDto>`)
```json
{ "items": [ /* AttendanceDto[] */ ], "page": 0, "limit": 20, "totalItems": 42, "totalPages": 3 }
```

---

## 3. Cấu trúc file cần tạo

Theo đúng Clean Architecture hiện có của repo (đối chiếu `features/reports/`, `features/staff/`):

```
lib/features/attendance/
├── data/
│   ├── models/attendance_models.dart
│   └── repositories/attendance_repository.dart
└── presentation/
    ├── providers/attendance_providers.dart
    ├── pages/attendance_page.dart
    └── widgets/
        ├── attendance_self_card.dart      (check-in/out cho STAFF/MANAGER, có dropdown chọn campaign)
        ├── attendance_table.dart          (danh sách cho MANAGER/ADMIN, có nút sửa/xoá)
        ├── attendance_edit_dialog.dart    (sửa — MANAGER/ADMIN)
        └── attendance_create_dialog.dart  (tạo thủ công — MANAGER/ADMIN)
```

Gợi ý gộp 1 route/1 trang `/attendance` thích ứng theo role thay vì 2 trang riêng — đỡ trùng logic:
- STAFF: chỉ thấy `AttendanceSelfCard` + lịch sử của mình.
- MANAGER: thấy cả `AttendanceSelfCard` **và** `AttendanceTable` (có nút tạo thủ công/sửa/xoá).
- ADMIN: thấy `AttendanceTable` với đầy đủ nút tạo thủ công/sửa/xoá (ADMIN **không còn** read-only).

### 3.1 `data/models/attendance_models.dart`

Dự án này dùng model thủ công (`fromJson`/`toJson`), không dùng freezed/json_serializable (xem `report_models.dart` để đối chiếu). Làm tương tự:

```dart
class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.campaignId,
    this.campaignName,
    this.eventId,
    this.eventName,
    required this.checkInAt,
    this.checkOutAt,
    this.checkInNote,
    this.checkOutNote,
    this.checkInLat, this.checkInLng,
    this.checkOutLat, this.checkOutLng,
    required this.status,
    this.workedMinutes,
  });

  final int id;
  final int employeeId;
  final String employeeName;
  final int? campaignId;
  final String? campaignName;
  final int? eventId;
  final String? eventName;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final String? checkInNote;
  final String? checkOutNote;
  final double? checkInLat, checkInLng, checkOutLat, checkOutLng;
  final String status; // OPEN | CLOSED
  final int? workedMinutes;

  bool get isOpen => status == 'OPEN';

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: (j['id'] as num).toInt(),
        employeeId: (j['employeeId'] as num).toInt(),
        employeeName: j['employeeName']?.toString() ?? '',
        campaignId: (j['campaignId'] as num?)?.toInt(),
        campaignName: j['campaignName']?.toString(),
        eventId: (j['eventId'] as num?)?.toInt(),
        eventName: j['eventName']?.toString(),
        checkInAt: DateTime.parse(j['checkInAt'] as String),
        checkOutAt: j['checkOutAt'] != null ? DateTime.parse(j['checkOutAt'] as String) : null,
        checkInNote: j['checkInNote']?.toString(),
        checkOutNote: j['checkOutNote']?.toString(),
        checkInLat: (j['checkInLat'] as num?)?.toDouble(),
        checkInLng: (j['checkInLng'] as num?)?.toDouble(),
        checkOutLat: (j['checkOutLat'] as num?)?.toDouble(),
        checkOutLng: (j['checkOutLng'] as num?)?.toDouble(),
        status: j['status'] as String,
        workedMinutes: (j['workedMinutes'] as num?)?.toInt(),
      );
}

class AttendancePage {
  AttendancePage({required this.items, required this.page, required this.totalItems, required this.totalPages});
  final List<AttendanceRecord> items;
  final int page;
  final int totalItems;
  final int totalPages;

  factory AttendancePage.fromJson(Map<String, dynamic> j) => AttendancePage(
        items: (j['items'] as List).map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList(),
        page: (j['page'] as num).toInt(),
        totalItems: (j['totalItems'] as num).toInt(),
        totalPages: (j['totalPages'] as num).toInt(),
      );
}
```

### 3.2 `data/repositories/attendance_repository.dart`

Theo đúng pattern của `ReportRepository` (dùng `DioClient`, unwrap `res.data!['data']`):

```dart
import '../../../../core/network/dio_client.dart';
import '../models/attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<AttendanceRecord> checkIn({
    required int campaignId, int? eventId, String? note, double? lat, double? lng,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance/check-in',
      data: {'campaignId': campaignId, 'eventId': eventId, 'note': note, 'lat': lat, 'lng': lng},
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendanceRecord> checkOut({String? note, double? lat, double? lng}) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance/check-out',
      data: {'note': note, 'lat': lat, 'lng': lng},
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// Manual entry by MANAGER/ADMIN (e.g. correcting a forgotten check-in).
  Future<AttendanceRecord> createManual({
    required int employeeId, required int campaignId, int? eventId,
    DateTime? checkInAt, DateTime? checkOutAt, String? checkInNote, String? checkOutNote,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance',
      data: {
        'employeeId': employeeId, 'campaignId': campaignId, 'eventId': eventId,
        'checkInAt': checkInAt?.toIso8601String(), 'checkOutAt': checkOutAt?.toIso8601String(),
        'checkInNote': checkInNote, 'checkOutNote': checkOutNote,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendancePage> myAttendance({int page = 0, int limit = 20}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/attendance/me',
      queryParameters: {'page': page, 'limit': limit},
    );
    return AttendancePage.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendancePage> listAttendance({
    int? employeeId, String? status, DateTime? from, DateTime? to,
    int page = 0, int limit = 20,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/attendance',
      queryParameters: {
        if (employeeId != null) 'employeeId': employeeId,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        'page': page, 'limit': limit,
      },
    );
    return AttendancePage.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendanceRecord> update(int id, {
    int? campaignId, int? eventId,
    DateTime? checkInAt, DateTime? checkOutAt, String? checkInNote, String? checkOutNote,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/attendance/$id',
      data: {
        'campaignId': campaignId,
        'eventId': eventId,
        'checkInAt': checkInAt?.toIso8601String(),
        'checkOutAt': checkOutAt?.toIso8601String(),
        'checkInNote': checkInNote,
        'checkOutNote': checkOutNote,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/api/v1/attendance/$id');
}
```

### 3.3 `presentation/providers/attendance_providers.dart`

Theo pattern `staff_registrations_provider.dart` (StateProvider cho filter + FutureProvider.autoDispose cho data):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider((ref) => AttendanceRepository());

// --- Self-service (STAFF/MANAGER) ---
final myAttendanceProvider = FutureProvider.autoDispose<AttendancePage>((ref) {
  return ref.read(attendanceRepositoryProvider).myAttendance(limit: 20);
});

// --- Team view (MANAGER/ADMIN) ---
class AttendanceFilter {
  const AttendanceFilter({this.employeeId, this.status, this.from, this.to});
  final int? employeeId;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  AttendanceFilter copyWith({int? employeeId, String? status, DateTime? from, DateTime? to}) =>
      AttendanceFilter(
        employeeId: employeeId ?? this.employeeId,
        status: status ?? this.status,
        from: from ?? this.from,
        to: to ?? this.to,
      );
}

final attendanceFilterProvider = StateProvider<AttendanceFilter>((ref) => const AttendanceFilter());

final teamAttendanceProvider = FutureProvider.autoDispose<AttendancePage>((ref) {
  final f = ref.watch(attendanceFilterProvider);
  return ref.read(attendanceRepositoryProvider).listAttendance(
        employeeId: f.employeeId, status: f.status, from: f.from, to: f.to, limit: 50,
      );
});

// --- Actions (call then invalidate the relevant provider(s) to refresh UI) ---
final attendanceActionsProvider = Provider((ref) => _AttendanceActions(ref));

class _AttendanceActions {
  _AttendanceActions(this._ref);
  final Ref _ref;
  AttendanceRepository get _repo => _ref.read(attendanceRepositoryProvider);

  Future<void> checkIn({required int campaignId, int? eventId, String? note}) async {
    await _repo.checkIn(campaignId: campaignId, eventId: eventId, note: note);
    _ref.invalidate(myAttendanceProvider);
  }

  Future<void> checkOut({String? note}) async {
    await _repo.checkOut(note: note);
    _ref.invalidate(myAttendanceProvider);
  }

  Future<void> createManual({
    required int employeeId, required int campaignId, int? eventId,
    DateTime? checkInAt, DateTime? checkOutAt, String? checkInNote, String? checkOutNote,
  }) async {
    await _repo.createManual(
      employeeId: employeeId, campaignId: campaignId, eventId: eventId,
      checkInAt: checkInAt, checkOutAt: checkOutAt, checkInNote: checkInNote, checkOutNote: checkOutNote,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> update(int id, {
    int? campaignId, int? eventId, DateTime? checkInAt, DateTime? checkOutAt, String? checkInNote, String? checkOutNote,
  }) async {
    await _repo.update(
      id, campaignId: campaignId, eventId: eventId,
      checkInAt: checkInAt, checkOutAt: checkOutAt, checkInNote: checkInNote, checkOutNote: checkOutNote,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _ref.invalidate(teamAttendanceProvider);
  }
}
```

### 3.4 UI

- **`AttendanceSelfCard`**: đọc `myAttendanceProvider`, lấy phần tử đầu tiên (mới nhất) để biết đang `OPEN` hay không → hiện nút "Check in" (nếu không có phiên mở) hoặc "Check out" (nếu đang mở), có ô ghi chú tuỳ chọn. Khi chưa `OPEN`, hiện thêm dropdown chọn campaign đang `ACTIVE` (bắt buộc) và event thuộc campaign đó (tuỳ chọn) trước khi bấm Check in — lấy danh sách qua campaign provider đã có sẵn (`campaign_list_page.dart`), filter `status == 'ACTIVE'`. Gọi qua `attendanceActionsProvider`. Bắt lỗi `DioException` với `statusCode == 409` → snackbar "Bạn đã check-in rồi" hoặc "Chiến dịch này hiện không mở" (phân biệt qua `e.response?.data?['message']`) / "Không có phiên đang mở để check-out"; `statusCode == 400` → snackbar thông báo chưa liên kết hồ sơ nhân viên hoặc event không thuộc campaign; `statusCode == 404` → chiến dịch không tồn tại.
- **`AttendanceTable`**: dùng `data_table_2` như `staff_registrations_page.dart`, cột: Nhân viên, Campaign/Event, Check-in, Check-out, Số giờ (`workedMinutes/60`), Trạng thái (chip OPEN/CLOSED), ghi chú. Có filter theo employee/status/date range (`attendanceFilterProvider`). Cột "Thao tác" (tạo thủ công/sửa/xoá) render khi `role == 'MANAGER' || role == 'ADMIN'`.
- **`AttendanceEditDialog`**: form sửa campaign/event (dropdown), `checkInAt`/`checkOutAt` (date+time picker) + 2 ô note, gọi `attendanceActionsProvider.update`.
- **`AttendanceCreateDialog`**: form tạo thủ công — chọn employee, campaign, event (tuỳ chọn), `checkInAt`/`checkOutAt` (tuỳ chọn) + 2 ô note, gọi `attendanceActionsProvider.createManual`.
- **`attendance_page.dart`**: lấy role qua `ref.watch(activeUserProvider).valueOrNull?.role` (pattern y hệt `campaign_list_page.dart`), dựng layout theo role:
  ```dart
  final role = ref.watch(activeUserProvider).valueOrNull?.role;
  final canSelfService = role == 'STAFF' || role == 'MANAGER';
  final canManage = role == 'MANAGER' || role == 'ADMIN';
  final canSeeTeam = role == 'MANAGER' || role == 'ADMIN';
  ```

---

## 4. Router + Sidebar (file `lib/app/router.dart`)

### 4.1 Thêm route (đặt cạnh route `/staff/registrations`, khoảng dòng 374-384)

```dart
GoRoute(
  path: '/attendance',
  pageBuilder: (context, state) => _buildPageWithSlideTransition(
    context: context,
    state: state,
    child: _RoleGate(
      allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
      child: const AttendancePage(),
    ),
  ),
),
```
(`_RoleGate` đã có sẵn trong file này — không cần viết lại.)

### 4.2 Thêm mục menu trong `_navItemsFor` (khoảng dòng 540-549, cùng khối `STAFF/MANAGER/ADMIN`)

```dart
if (role == 'STAFF' || role == 'MANAGER' || role == 'ADMIN') {
  ...
  items.add(_NavItem('/attendance', l10n.attendance,
      Icons.access_time_outlined, Icons.access_time));
}
```

---

## 5. l10n — thêm key vào `lib/l10n/app_en.arb` và `lib/l10n/app_vi.arb`

| Key | EN | VI |
|---|---|---|
| `attendance` | Attendance | Chấm công |
| `checkIn` | Check in | Check-in |
| `checkOut` | Check out | Check-out |
| `openSession` | Currently checked in | Đang trong ca |
| `noOpenSession` | Not checked in | Chưa check-in |
| `workedHours` | Worked hours | Số giờ làm |
| `attendanceCorrectionNote` | Correction note | Ghi chú điều chỉnh |
| `alreadyCheckedIn` | You are already checked in | Bạn đã check-in rồi |
| `noOpenSessionToCheckOut` | No open session to check out | Không có phiên đang mở để check-out |
| `employeeNotLinked` | Your account is not linked to an employee record | Tài khoản của bạn chưa được liên kết với hồ sơ nhân viên |
| `noActiveCampaign` | No campaign is currently open | Hiện không có chiến dịch nào đang mở |
| `campaignNotOpenForCheckIn` | This campaign is not open for check-in | Chiến dịch này hiện không mở để check-in |
| `selectCampaign` | Select campaign | Chọn chiến dịch |
| `selectEventOptional` | Select event (optional) | Chọn sự kiện (không bắt buộc) |

Chạy `flutter gen-l10n` (hoặc build lại) sau khi thêm để sinh getter trong `app_localizations*.dart`.

---

## 6. Error handling

Repository/actions nên để lỗi Dio nổi lên tự nhiên (không nuốt lỗi), UI bắt theo `DioException.response?.statusCode`:

```dart
try {
  await ref.read(attendanceActionsProvider).checkIn(campaignId: selectedCampaignId!);
} on DioException catch (e) {
  final code = e.response?.statusCode;
  final serverMessage = e.response?.data?['message']?.toString();
  final l10n = AppLocalizations.of(context)!;
  final msg = switch (code) {
    409 when serverMessage?.contains('open for check-in') == true => l10n.campaignNotOpenForCheckIn,
    409 => l10n.alreadyCheckedIn,
    404 => l10n.noActiveCampaign,
    400 => l10n.employeeNotLinked,
    _ => serverMessage ?? e.message,
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg!)));
}
```
Ghi chú: 409 dùng chung cho cả "đã check-in rồi" và "campaign không mở" — phân biệt bằng nội dung `message` trả về từ BE (`AttendanceService.ensureCampaignOpenForCheckIn` ném `"Campaign is not open for check-in"`; `ensureNoOpenSession` ném `"Employee already has an open check-in session"`).

---

## 7. Test cần viết (đối chiếu `FE/test/`)

- `test/features/attendance/attendance_repository_test.dart` — mock Dio, verify request path/params đúng (kể cả `campaignId`/`eventId`) và parse response đúng (giống style test hiện có cho reports/notifications).
- Widget test cho `AttendanceSelfCard`: hiện nút "Check in" khi chưa có phiên mở (disable nếu không có campaign `ACTIVE`), hiện nút "Check out" khi có; nút tạo thủ công/sửa/xoá trong `AttendanceTable` hiện với cả role MANAGER và ADMIN, ẩn với role khác.

---

## 8. Ngoài phạm vi (xác nhận với nhóm trước khi làm thêm)

- Chưa cần bắn Firebase Analytics event cho check-in/out (không nằm trong yêu cầu Lab3).
- Chưa validate `lat`/`lng` theo vị trí trường/văn phòng (geofencing) — nếu cần, phải làm ở BE trước, không tự chế ở FE.

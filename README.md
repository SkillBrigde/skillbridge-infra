# SkillBridge Infrastructure

Compose **local** cho backend SkillBridge. Mục tiêu hạ tầng nhóm là dùng PostgreSQL và, khi tích hợp file, MinIO chung trên môi trường development; Redis chạy cạnh từng API local, RabbitMQ chưa cần. Web deploy trên Vercel từ repo `skillbridge-web`. Compose này chưa cấu hình dịch vụ chung trên EC2 và không deploy web hoặc API.

## Chạy hoàn toàn local khi chưa nối hạ tầng chung

Yêu cầu: Docker Desktop/Engine đang chạy, Docker Compose, .NET 10 SDK và Node.js 24.x nếu phát triển cả web.

```powershell
# Trong repo skillbridge-infra
.\scripts\start.ps1
docker compose ps
```

Script chỉ tạo `.env` từ `.env.example` khi chưa có; không ghi đè cấu hình cá nhân. Mặc định chỉ chạy **PostgreSQL 17** và **Redis 7.4**, cùng mở cổng trên `127.0.0.1`. File mẫu dùng mật khẩu thử nghiệm local, không dùng cho môi trường chia sẻ hoặc production.

RabbitMQ và MinIO chỉ cần khi phát triển tích hợp tương ứng:

```powershell
.\scripts\start.ps1 -Optional
# Tương đương: docker compose --profile optional up -d
```

API hiện đăng ký `InMemoryEventBus`, chưa dùng RabbitMQ làm broker; MinIO chưa được tích hợp làm kho file. Vì vậy không cần bật hai dịch vụ này để chạy API hiện tại.

| Dịch vụ | Địa chỉ local | Mặc định |
|---|---|---|
| PostgreSQL | `localhost:5432` | Có |
| Redis | `localhost:6379` | Có |
| RabbitMQ AMQP / UI | `localhost:5672` / `http://localhost:15672` | Tùy chọn |
| MinIO API / UI | `http://localhost:9000` / `http://localhost:9001` | Tùy chọn |

## Kết nối API local

Trong repo `skillbridge-api`, sao chép `.env.example` thành `.env`, tạo `Jwt__SecretKey` ngẫu nhiên dài ít nhất 32 byte, rồi sửa **các giá trị kết nối theo đúng `.env` của repo infra**. Với file mẫu infra mới tạo, các giá trị cần dùng là:

```dotenv
ConnectionStrings__Database=Host=localhost;Port=5432;Database=skillbridge;Username=skillbridge;Password=skillbridge_dev_only
Redis__ConnectionString=localhost:6379,password=skillbridge_dev_only
```

```powershell
# Trong repo skillbridge-api
dotnet run --project src/Api --launch-profile http
# Kiểm tra: http://localhost:5000/health/live
```

File `.env.example` của API còn phục vụ Compose cũ trong repo API, nên mật khẩu mẫu của nó khác repo infra. Chọn **một** bộ Compose để tránh trùng cổng và volume. API ở chế độ Development tự chạy EF Core migrations khi khởi động: chỉ nối tới database local mới hoặc database đã được kiểm tra kế hoạch migration.

## Khi nhóm dùng hạ tầng development chung

- **PostgreSQL:** cả nhóm dùng đúng một database development trên EC2 để thấy cùng dữ liệu. Mỗi người chạy API trên máy mình và kết nối tới database này. Chỉ chủ dự án/quy trình được giao áp dụng EF migrations: API Development hiện tự chạy migration khi khởi động, nên cần đổi cấu hình này trước khi để nhiều branch cùng kết nối database chung.
- **MinIO:** dùng chung endpoint/bucket khi chức năng upload/file được tích hợp. Mã API hiện chưa gọi MinIO, nên chưa cần bật dịch vụ này để chạy các tính năng hiện tại. Cấp access key riêng hoặc quyền theo bucket; không phát tán root credentials trong repo.
- **Redis:** API hiện cần Redis cho rate limiting, nhưng mỗi thành viên chỉ cần một Redis local. Trong repo này chạy `docker compose up -d redis` để không khởi động PostgreSQL local. API chạy trên server cần Redis của server; chỉ cần Redis chung giữa nhiều API instance khi muốn chia sẻ trạng thái rate limit.
- **RabbitMQ:** API hiện dùng `InMemoryEventBus`, nên không cần chạy local hoặc chung.

PostgreSQL EC2 được nhóm mô tả là chỉ lắng nghe ở `127.0.0.1:5432`; máy thành viên không thể kết nối trực tiếp. Cần SSH tunnel riêng cho từng người hoặc một mạng riêng do chủ dự án cấp. MinIO chung cũng cần endpoint riêng được bảo vệ. Chưa có cấu hình truy cập chung hoặc xác nhận triển khai MinIO trên EC2 trong repo này.

Nếu chạy web local, trong repo `skillbridge-web` sao chép `.env.example` thành `.env.local` (`API_BASE_URL=http://localhost:5000`), rồi chạy `npm ci` và `npm run dev`. Web production trên Vercel cần `API_BASE_URL` trỏ tới **API HTTPS mà Vercel truy cập được**; URL `localhost` hoặc database EC2 không thể thay thế API này.

Hiện hợp đồng đăng nhập giữa web và API chưa khớp: API trả access token trong JSON và refresh token bằng cookie, còn BFF web chờ cả thông tin người dùng và refresh token trong JSON. Chạy đủ các tiến trình mới kiểm tra được trang/health; cần đồng bộ hợp đồng auth trước khi coi luồng đăng nhập là hoàn tất.

## Dừng và bảo toàn dữ liệu

```powershell
docker compose down
# Nếu đã bật dịch vụ tùy chọn:
docker compose --profile optional down
```

`down` giữ named volumes. Không dùng `down --volumes` nếu còn dữ liệu. Init SQL trong `postgres/init` chỉ chạy khi PostgreSQL tạo volume mới; EF Core migrations thuộc từng module quản lý bảng.

## Thành viên cần được cấp gì?

- Quyền đọc ba repo `skillbridge-infra`, `skillbridge-api`, `skillbridge-web`, cùng URL Vercel Preview/Production và quy trình pull request.
- Cấu hình **local** từ các file `.env.example`; mỗi người giữ `.env`/`.env.local` riêng và tự tạo JWT key. Khi hạ tầng chung sẵn sàng, chủ dự án cấp endpoint và quyền truy cập cùng database development, cùng MinIO khi đã tích hợp file, qua kênh bảo mật; không đưa secret lên Git hoặc nhóm chat.
- Người cần kiểm thử môi trường chung được cấp tài khoản ứng dụng test và quyền kết nối DB/MinIO đúng phạm vi. Chỉ chủ dự án giữ quyền deploy EC2/Vercel/GitHub secrets. Quyền kết nối dịch vụ không đồng nghĩa với quyền deploy.

PostgreSQL trên EC2 đang là môi trường thử nghiệm theo mô tả của nhóm, không nằm trong Compose local này. Việc deploy API lên EC2 và cấu hình Vercel gọi API cần được hoàn tất riêng trước khi web production dùng được backend.

# Xianxia Chat - DevOps Lab Project

Dự án hoàn chỉnh phục vụ cho việc thực hành DevOps (Containerization, IaC, CI/CD, AWS Cloud Architecture).

---

## 🏗️ Cấu trúc dự án

```
ProjectLab/
├── backend/                  # Node.js Express + Socket.io API (PostgreSQL)
│   ├── src/
│   │   ├── config/db.js      # Adapter kết nối PostgreSQL (pg pool)
│   │   ├── models/           # Models truy vấn DB
│   │   └── app.js            # Express app + /health endpoint + serve frontend
│   ├── schema.sql            # Schema chuẩn PostgreSQL 16
│   ├── package.json
│   └── .env.example
├── frontend/                 # Web SPA (Vanilla HTML/CSS/JS ES Modules)
│   ├── index.html
│   ├── css/
│   └── js/
├── iac/                      # Hạ tầng AWS quản lý bằng Terraform
│   ├── environments/dev/     # Root module cho môi trường dev
│   └── modules/              # 5 modules: networking, security-groups, alb, compute, database
├── Dockerfile                # Dockerfile đóng gói ứng dụng (Backend + Frontend)
├── docker-compose.yml        # Chạy full-stack local (App + PostgreSQL 16)
└── .gitignore
```

---

## 🚀 Luồng hoạt động

1. **Local Lab (Thực hành trên máy qua Docker)**:
   - Chạy lệnh: `docker compose up -d`
   - Docker sẽ khởi chạy 2 containers:
     - **`app` (port 3000)**: Backend Node.js phục vụ REST API, WebSocket và Frontend SPA.
     - **`db` (port 5432)**: PostgreSQL 16 tự động khởi tạo bảng từ `schema.sql`.
   - Truy cập ngay tại: **`http://localhost:3000`** (Giao diện web + API + WebSocket).

2. **Cloud Lab (Triển khai lên AWS qua Terraform)**:
   - Truy cập thư mục: `cd iac/environments/dev`
   - Cấu hình file `backend.hcl` và `terraform.tfvars`.
   - Chạy lệnh:
     ```bash
     terraform init -backend-config=backend.hcl
     terraform plan
     terraform apply
     ```
   - Hệ thống tự động dựng:
     - **VPC** (Public & Private subnets trên 2 AZ).
     - **RDS PostgreSQL 16** (Private subnet, credentials tự sinh vào Secrets Manager).
     - **ALB** (Public subnet, kiểm tra sức khỏe qua `/health`, SSL/TLS).
     - **ASG + EC2** (Private subnet, quản trị qua AWS SSM Session Manager không cần mở port 22).

---

## 🔑 Các điểm cốt lõi đã được đồng bộ

- **Cơ sở dữ liệu**: Đã chuyển đổi hoàn toàn từ MySQL sang **PostgreSQL 16** để khớp 100% với tài nguyên `aws_db_instance` trong Terraform.
- **Health Check Endpoint**: Backend có sẵn endpoint `/health` trả về HTTP 200 `{ status: "ok" }`, khớp với cấu hình health check của ALB Target Group.
- **Port**: Cổng ứng dụng thống nhất là **`3000`** xuyên suốt từ Backend, Dockerfile, Docker Compose đến Terraform Security Groups và ALB Target Group.

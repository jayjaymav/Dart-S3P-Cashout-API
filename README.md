
# 💸 S3P Cashout Dart Integration

This project provides a full Dart implementation of the S3P API cashout flow using HMAC-SHA1 authentication. It replicates the original Python script to perform:

- ✅ Fetch all available cashout services
- ✅ Query a specific service
- ✅ Generate a quote
- ✅ Initiate a cashout collection
- ✅ Verify the transaction status

> Built with Dart for seamless command-line and backend integration.

---

## 🛠 Project Structure

```bash
.
├── bin/
│   └── cashout_s3p.dart        # Main Dart script
├── pubspec.yaml                # Dependencies
└── .gitignore                  # Git ignored files


---
### 🚀 Getting Started
1. Clone the repository

git clone https://github.com/YOUR_USERNAME/s3p-cashout-dart.git
cd s3p-cashout-dart

2. Install dependencies

dart pub get

3. Run the integration

dart run bin/cashout_s3p.dart

📦 Dependencies

Package	--> Purpose
http	--> For making HTTP requests
crypto	--> For HMAC-SHA1 signing
convert	--> For base64 and UTF-8 encoding
These are declared in the pubspec.yaml file.

📋 Usage Flow
GET /v2/cashout – Fetch list of cashout services

GET /v2/cashout?serviceid=... – Get info on specific service

POST /v2/quotestd – Generate a quote ID

POST /v2/collectstd – Perform the transaction using the quote

GET /v2/verifytx?ptn=... – Verify the transaction status after a short delay

🔐 Authentication
This integration uses HMAC-SHA1 signing to secure each API request. The base string construction and signature logic are built to match the original Python backend for exact compatibility with Smobilpay’s servers.

📣 Notes
Be sure to replace the test s3pKey and s3pSecret with production keys in secure environments.

For production, add proper error handling and logging.

This script uses a 30-second wait before verifying the transaction status (can be adjusted).

🤝 Contributing
PRs and feedback are welcome! If you're using S3P in Dart and want to improve this template, feel free to fork and extend it.

🧑‍💻 Author
Jerry Jonah

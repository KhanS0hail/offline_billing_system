# Offline Billing & Invoicing System

![App Version](https://img.shields.io/badge/version-1.0.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-Desktop%20%26%20Cross--Platform-02569B?logo=flutter)
![Database](https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite)

A fast, offline-first GST Billing & Invoicing application built with Flutter. Designed for seamless invoice creation, customer ledger tracking, sales performance reporting, and professional PDF document generation across macOS Desktop, Windows, and Android.

---

## 🌟 Key Features

### 🏢 1. Company Profile Management
- Complete business branding setup: Company Name, Tagline, GSTIN, Phone, Email, and Address.
- Banking & Payment details (Bank Name, Branch, Account Number, IFSC Code, UPI ID).
- Custom Logo & Digital Signature uploads.
- Default Terms & Conditions configuration.

### 📦 2. Products & Services Catalog
- Manage products and services with HSN/SAC codes, measurement units, and GST rates (0%, 5%, 12%, 18%, 28%).
- Optional selling prices with `0.0` default.
- Real-time catalog search isolated from active invoice editing.

### 👥 3. Customer Directory
- Detailed customer profiles with GSTIN, State Codes, Contact Info, and Opening Balances.
- Quick customer lookup and management.

### 📄 4. Invoice Creation & Editing
- **Directly Editable Inline Item Table**: Fast desktop keyboard navigation.
- **Product Selector Modal**: Non-writable searchable product dropdown with an in-modal `+ Add New Product` shortcut.
- **Dynamic Tax Calculation**: Automatic CGST, SGST, IGST, base taxable value, discount, loading/freight charges, and grand total computation.
- **Streamlined Workflow**: Saved directly as `Unpaid` invoices with two main action buttons:
  - `Save` — Saves invoice and returns to the Invoice List.
  - `Save & Preview PDF` — Saves invoice and immediately opens the PDF preview.

### 📊 5. Customer Ledger & Payment Tracking
- **Selected Customer Statement**: Unified 6-column running ledger statement (Invoices, Receipts, Debit, Credit, Running Balance).
- **All Customers Combined Payments**: View all payment records across all customers with a dedicated Customer/Company Name column.
- Record payment receipts with payment modes (UPI, NEFT/RTGS, Cash, Cheque) and notes.

### 📈 6. Sales Performance Reports
- Period filtering: Monthly, Annual Financial Year, or Custom Date Ranges.
- Flexible report types: `Full Comprehensive`, `Invoice-Wise Only`, `Product-Wise Only`, `Customer-Wise Only`.
- Toggleable **Revenue & Financial Summary** header table in PDF reports.
- Omitted Status column for streamlined `Invoice-Wise Only` reports.

### 🖨️ 7. PDF Export & Printing
- Tax Invoices formatted with separate **Bank Name** and **Branch** rows.
- Customer Account Statements matching Invoice PDF presentation styling.
- Native printing and PDF saving support via the `printing` package.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK `>=3.3.4 <4.0.0`)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [SQLite](https://pub.dev/packages/sqflite) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)
- **PDF Generation & Printing**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)

---

## 🚀 Getting Started

### Prerequisites

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Enable target desktop / mobile platforms:
   ```bash
   # Enable macOS Desktop
   flutter config --enable-macos-desktop

   # Enable Windows Desktop
   flutter config --enable-windows-desktop
   ```

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/offline_billing_system.git
   cd offline_billing_system
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # macOS Desktop
   flutter run -d macos

   # Windows Desktop
   flutter run -d windows

   # Android Device / Emulator
   flutter run -d android
   ```

4. Build production release bundle:
   ```bash
   # macOS Release Bundle (.app)
   flutter build macos --release

   # Windows Executable (.exe)
   flutter build windows --release

   # Android APK (.apk)
   flutter build apk --release

   # Android App Bundle (.aab for Google Play Store)
   flutter build appbundle --release
   ```

---

## 📌 Version History

- **v1.0.0.0** — Initial Production Release
  - Complete GST Billing, Customer Ledger, PDF Invoicing & Reports.

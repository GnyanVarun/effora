# 🚀 Effora — Empower Your Hustle

Effora is a hustle management app designed to help freelancers, creators, and side-hustlers track income, expenses, tasks, and overall productivity — even offline. It syncs to the cloud for multi-device access.

# 📱 Tech Stack

## 💙 Flutter (Dart)

<ul>
<li>Clean and responsive UI</li>

<li>Dark mode support via SharedPreferences</li>

<li>Platform support: Android, Windows, and ready for iOS</li>
</ul>

## 📦 Local Storage

<ul>
<li>Hive: Lightweight, NoSQL database for offline-first architecture</li>
</ul>

## ☁️ Cloud Sync

<ul>
<li>Supabase (PostgreSQL + Realtime backend):</li>

<li>Auth (email/password)</li>

<li>Realtime sync of Hustles, Income, Expenses, Tasks</li>

<li>RLS policies based on auth.uid</li>

<li>Profile sync (username, avatar, country)</li>
</ul>

## 🔐 Auth & Verification

<ul>
<li>Email/password sign-up and login via Supabase</li>

<li>Email confirmation with redirect to login using deep links</li>

<li>Password reset with confirmation email & custom UI</li>

<li>This project is a starting point for a Flutter application.</li>
</ul>

## 📊 Features

| Module            | Features                                                         |
| ----------------- | ---------------------------------------------------------------- |
| **Hustles**       | Add/track multiple hustles with their own currency               |
| **Income**        | Add, edit, delete, visualize monthly income                      |
| **Expenses**      | Add, edit, delete, see expense trends                            |
| **Tasks**         | Add, delete, complete, and get reminders                         |
| **Reports**       | Monthly income/expense charts, pie charts, net profit per hustle |
| **Settings**      | Username update, dark mode, profile pic, currency, logout        |
| **Splash & Logo** | Native splash screen with app icon                               |


## 🌐 Deep Linking

<ul>
 <li> Handled via app_links. </li>

<li>GitHub Pages used as the email confirmation redirect:
https://gnyanvarun.github.io/effora-confirmation-redirect/ </li>
</ul>

## 🛠️ Project Setup
### Packages Used:
<ul>
  <li>flutter_native_splash: ^2.3.5</li>
  <li>flutter_launcher_icons: ^0.13.1</li>
  <li>supabase_flutter: ^2.9.1</li>
  <li>hive + hive_flutter: Local data store</li>
  <li>fl_chart: For bar & pie charts</li>
  <li>flutter_local_notifications + timezone: Task reminders</li>
  <li>shared_preferences: Dark mode & sync flags</li>
</ul>

## Screenshots of the Application.

### Dashboard Screen:

<img src="https://github.com/user-attachments/assets/2a1a442e-46bc-45ab-9f41-ebc11aba3fa1" alt= "Screenshot" width= 300/>

Your personalized hub to track income, expenses, tasks, and hustle insights — all in one glance.

## Hustles Screen:

<img src="https://github.com/user-attachments/assets/4e4dffc2-94d3-4c3c-bae3-cceece205ae2" alt="Screenshot" width=300/>



## Incomes Screen:

<img src="https://github.com/user-attachments/assets/7e104e27-fc53-4420-88fd-9cac391b9bce" alt="Screenshot" width= 300/>

Log and view income sources associated with different hustles. Supports editing and currency customization.

## Expense Screen:

<img src="https://github.com/user-attachments/assets/3bdb0076-70ce-4b71-9d1c-bc77c0691d7c" alt="Screenshot" width= 300/>

Track your business-related spending by hustle, categorize it, and stay financially aware.

## Tasks Screen:

<img src ="https://github.com/user-attachments/assets/90705a70-e895-422d-b172-19d30dea6198" alt="Screenshot" width= 300/>

Manage your hustle-related tasks with due dates, priorities, and reminder notifications.

## Reports Screen:

<img src ="https://github.com/user-attachments/assets/444949a7-db4a-422c-8e34-f51ac281c476" alt="Screenshot" width= 300/>

Visual analytics including bar charts and pie charts to help you understand trends in income, expenses, and task performance.

## Profile Settings:

<img src ="https://github.com/user-attachments/assets/2bd466a4-ccd2-4ee7-9670-7e8ddbfbaada" alt="Screenshot" width= 300/>

Update profile, toggle dark mode, upload avatar, and view app version & licensing information.


## Native Support:

<ul>
  <li>✅ Android with custom icon/splash</li>
  <li>✅ Windows (CMake icon configured)</li>
  <li>⚙️ iOS (configured for build, pending Xcode setup)</li>
</ul>

## 🔧 Dev Tips

<ul>
  <li>Ensure .env or constants.dart includes Supabase URL and anon key</li>
  <li>Customize splash screen via flutter_native_splash.yaml</li>
  <li>Upload icons in assets/logos/ and reference them in pubspec.yaml</li>
</ul>

## 📜 License

Licensed under the Apache License 2.0.

## Author

Built by Varun Vailala <br>
"Empower your hustle, own your success."

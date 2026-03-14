import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'donations'**
  String get donations;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @donorName.
  ///
  /// In en, this message translates to:
  /// **'Donor Name'**
  String get donorName;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @totalDonations.
  ///
  /// In en, this message translates to:
  /// **'Total Donations'**
  String get totalDonations;

  /// No description provided for @todayCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todayCollection;

  /// No description provided for @pendingReceipts.
  ///
  /// In en, this message translates to:
  /// **'Pending Receipts'**
  String get pendingReceipts;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @panCard.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get panCard;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt Number'**
  String get receiptNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @selectYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectYourLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @ganpatiBappaMorya.
  ///
  /// In en, this message translates to:
  /// **'Ganpati Bappa Morya! 🙏'**
  String get ganpatiBappaMorya;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You'**
  String get thankYou;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @newDonation.
  ///
  /// In en, this message translates to:
  /// **'New Donation'**
  String get newDonation;

  /// No description provided for @collectorHome.
  ///
  /// In en, this message translates to:
  /// **'Collector Home'**
  String get collectorHome;

  /// No description provided for @adminHome.
  ///
  /// In en, this message translates to:
  /// **'Admin Home'**
  String get adminHome;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @donorPhone.
  ///
  /// In en, this message translates to:
  /// **'Donor Phone'**
  String get donorPhone;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterDonorName.
  ///
  /// In en, this message translates to:
  /// **'Enter donor name'**
  String get enterDonorName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @enterNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter notes (optional)'**
  String get enterNotes;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method:'**
  String get selectPaymentMethod;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @donationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Donation Submitted Successfully!'**
  String get donationSubmitted;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline. Will sync when online.'**
  String get savedOffline;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountGreaterThanZero;

  /// No description provided for @pleaseEnterDonorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter donor name'**
  String get pleaseEnterDonorName;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @receiptNo.
  ///
  /// In en, this message translates to:
  /// **'Receipt No.'**
  String get receiptNo;

  /// No description provided for @donor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get donor;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @receiptDetails.
  ///
  /// In en, this message translates to:
  /// **'Receipt Details'**
  String get receiptDetails;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code to Pay'**
  String get scanQrCode;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment confirmation...'**
  String get waitingForPayment;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'I have received the payment'**
  String get paymentReceived;

  /// No description provided for @cancelPayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelPayment;

  /// No description provided for @shareViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share receipt via WhatsApp to'**
  String get shareViaWhatsapp;

  /// No description provided for @whatsappToDonor.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp to Donor'**
  String get whatsappToDonor;

  /// No description provided for @otherApps.
  ///
  /// In en, this message translates to:
  /// **'Other Apps'**
  String get otherApps;

  /// No description provided for @receiptSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt shared successfully'**
  String get receiptSharedSuccessfully;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentStatusCancelled;

  /// No description provided for @donorSearch.
  ///
  /// In en, this message translates to:
  /// **'Donor Search'**
  String get donorSearch;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @searchDonor.
  ///
  /// In en, this message translates to:
  /// **'Search Donor'**
  String get searchDonor;

  /// No description provided for @donorHistory.
  ///
  /// In en, this message translates to:
  /// **'Donor History'**
  String get donorHistory;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @pendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Pending Amount'**
  String get pendingAmount;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @recurringDonor.
  ///
  /// In en, this message translates to:
  /// **'Recurring Donor'**
  String get recurringDonor;

  /// No description provided for @collector.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get collector;

  /// No description provided for @mandalSettings.
  ///
  /// In en, this message translates to:
  /// **'Mandal Settings'**
  String get mandalSettings;

  /// No description provided for @mandalInfo.
  ///
  /// In en, this message translates to:
  /// **'Mandal Information'**
  String get mandalInfo;

  /// No description provided for @mandalName.
  ///
  /// In en, this message translates to:
  /// **'Mandal Name'**
  String get mandalName;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get registrationNumber;

  /// No description provided for @officials.
  ///
  /// In en, this message translates to:
  /// **'Officials'**
  String get officials;

  /// No description provided for @president.
  ///
  /// In en, this message translates to:
  /// **'President'**
  String get president;

  /// No description provided for @vicePresident.
  ///
  /// In en, this message translates to:
  /// **'Vice President'**
  String get vicePresident;

  /// No description provided for @secretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get secretary;

  /// No description provided for @treasurer.
  ///
  /// In en, this message translates to:
  /// **'Treasurer'**
  String get treasurer;

  /// No description provided for @receiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Receipt Footer'**
  String get receiptFooter;

  /// No description provided for @footerMessage.
  ///
  /// In en, this message translates to:
  /// **'Footer Message'**
  String get footerMessage;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @uploadQR.
  ///
  /// In en, this message translates to:
  /// **'Upload QR Code'**
  String get uploadQR;

  /// No description provided for @logoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Logo uploaded successfully!'**
  String get logoUploaded;

  /// No description provided for @qrUploaded.
  ///
  /// In en, this message translates to:
  /// **'QR code uploaded successfully!'**
  String get qrUploaded;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully!'**
  String get settingsSaved;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @reportsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAnalytics;

  /// No description provided for @donationReports.
  ///
  /// In en, this message translates to:
  /// **'Donation Reports'**
  String get donationReports;

  /// No description provided for @collectorPerformance.
  ///
  /// In en, this message translates to:
  /// **'Collector Performance'**
  String get collectorPerformance;

  /// No description provided for @categoryWise.
  ///
  /// In en, this message translates to:
  /// **'Category-wise'**
  String get categoryWise;

  /// No description provided for @methodWise.
  ///
  /// In en, this message translates to:
  /// **'Method-wise'**
  String get methodWise;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @downloadCSV.
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get downloadCSV;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @bulkEntry.
  ///
  /// In en, this message translates to:
  /// **'Bulk Entry'**
  String get bulkEntry;

  /// No description provided for @addMultipleDonations.
  ///
  /// In en, this message translates to:
  /// **'Add Multiple Donations'**
  String get addMultipleDonations;

  /// No description provided for @uploadCSV.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV'**
  String get uploadCSV;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get special;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @totalDonationsCount.
  ///
  /// In en, this message translates to:
  /// **'Total Donations'**
  String get totalDonationsCount;

  /// No description provided for @recentDonations.
  ///
  /// In en, this message translates to:
  /// **'Recent Donations'**
  String get recentDonations;

  /// No description provided for @todaysStats.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Stats'**
  String get todaysStats;

  /// No description provided for @overallStats.
  ///
  /// In en, this message translates to:
  /// **'Overall Stats'**
  String get overallStats;

  /// No description provided for @upiCollection.
  ///
  /// In en, this message translates to:
  /// **'UPI Collection'**
  String get upiCollection;

  /// No description provided for @cashCollection.
  ///
  /// In en, this message translates to:
  /// **'Cash Collection'**
  String get cashCollection;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @changeTo.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeTo;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @viewAllDonations.
  ///
  /// In en, this message translates to:
  /// **'View All Donations'**
  String get viewAllDonations;

  /// No description provided for @reportsAndStats.
  ///
  /// In en, this message translates to:
  /// **'Reports & Statistics'**
  String get reportsAndStats;

  /// No description provided for @bulkDonationEntry.
  ///
  /// In en, this message translates to:
  /// **'Bulk Donation Entry'**
  String get bulkDonationEntry;

  /// No description provided for @searchDonorMenu.
  ///
  /// In en, this message translates to:
  /// **'Search Donor'**
  String get searchDonorMenu;

  /// No description provided for @pendingPaymentsMenu.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPaymentsMenu;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @collectorPanel.
  ///
  /// In en, this message translates to:
  /// **'Collector Panel'**
  String get collectorPanel;

  /// No description provided for @allDonations.
  ///
  /// In en, this message translates to:
  /// **'All Donations'**
  String get allDonations;

  /// No description provided for @searchByNamePhoneReceipt.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone or receipt number'**
  String get searchByNamePhoneReceipt;

  /// No description provided for @noDonationsFound.
  ///
  /// In en, this message translates to:
  /// **'No donations found'**
  String get noDonationsFound;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// No description provided for @upiPayment.
  ///
  /// In en, this message translates to:
  /// **'UPI Payment'**
  String get upiPayment;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterLabel;

  /// No description provided for @selectDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDateLabel;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @searchByNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone'**
  String get searchByNameEmailPhone;

  /// No description provided for @addUserButton.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUserButton;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @noDonationsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No donations in this period'**
  String get noDonationsInPeriod;

  /// No description provided for @collectorPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Collector Performance'**
  String get collectorPerformanceTitle;

  /// No description provided for @noCollectorData.
  ///
  /// In en, this message translates to:
  /// **'No collector data available'**
  String get noCollectorData;

  /// No description provided for @noDonorData.
  ///
  /// In en, this message translates to:
  /// **'No donor data available'**
  String get noDonorData;

  /// No description provided for @paymentMethodAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Payment Method Analysis'**
  String get paymentMethodAnalysis;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @perDonation.
  ///
  /// In en, this message translates to:
  /// **'per donation'**
  String get perDonation;

  /// No description provided for @selectDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDateTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingLabel;

  /// No description provided for @saveAllDonations.
  ///
  /// In en, this message translates to:
  /// **'Save All Donations'**
  String get saveAllDonations;

  /// No description provided for @pleaseAddDonation.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one donation'**
  String get pleaseAddDonation;

  /// No description provided for @successfullyAdded.
  ///
  /// In en, this message translates to:
  /// **'Successfully added'**
  String get successfullyAdded;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @donationNumber.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donationNumber;

  /// No description provided for @donorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get donorNameRequired;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @validAmount.
  ///
  /// In en, this message translates to:
  /// **'Valid amount'**
  String get validAmount;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @cashOption.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashOption;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @addNewDonation.
  ///
  /// In en, this message translates to:
  /// **'Add new donation'**
  String get addNewDonation;

  /// No description provided for @donorInformation.
  ///
  /// In en, this message translates to:
  /// **'Donor Information'**
  String get donorInformation;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneOptional;

  /// No description provided for @amountAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Amount & Payment Method'**
  String get amountAndPayment;

  /// No description provided for @amountInRupees.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amountInRupees;

  /// No description provided for @enterAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmountLabel;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @donationType.
  ///
  /// In en, this message translates to:
  /// **'Donation Type'**
  String get donationType;

  /// No description provided for @cashHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get cashHandLabel;

  /// No description provided for @recurringDonorLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring Donor'**
  String get recurringDonorLabel;

  /// No description provided for @recurringDonorDesc.
  ///
  /// In en, this message translates to:
  /// **'This donor donates regularly'**
  String get recurringDonorDesc;

  /// No description provided for @paymentReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceivedLabel;

  /// No description provided for @paymentReceivedDesc.
  ///
  /// In en, this message translates to:
  /// **'Amount received now'**
  String get paymentReceivedDesc;

  /// No description provided for @paymentPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPendingLabel;

  /// No description provided for @paymentPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Amount to be received later (Give receipt now)'**
  String get paymentPendingDesc;

  /// No description provided for @showQRCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get showQRCode;

  /// No description provided for @acceptCash.
  ///
  /// In en, this message translates to:
  /// **'Accept Cash'**
  String get acceptCash;

  /// No description provided for @processingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingLabel;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @newDonationButton.
  ///
  /// In en, this message translates to:
  /// **'New Donation'**
  String get newDonationButton;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noInfoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No information available'**
  String get noInfoAvailable;

  /// No description provided for @noDonationsYet.
  ///
  /// In en, this message translates to:
  /// **'No donations yet'**
  String get noDonationsYet;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @searchDonorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter name or phone number...'**
  String get searchDonorPlaceholder;

  /// No description provided for @searchDonorInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter donor name or phone number to search'**
  String get searchDonorInstruction;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading information'**
  String get loadingError;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @cancelDonation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Donation'**
  String get cancelDonation;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancellationReason;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @paymentReceivedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Payment Received?'**
  String get paymentReceivedQuestion;

  /// No description provided for @yesReceived.
  ///
  /// In en, this message translates to:
  /// **'Yes, Received'**
  String get yesReceived;

  /// No description provided for @noPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'No pending payments! 🎉'**
  String get noPendingPayments;

  /// No description provided for @pendingPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPaymentsTitle;

  /// No description provided for @receivedButton.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedButton;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get comingSoon;

  /// No description provided for @printerTest.
  ///
  /// In en, this message translates to:
  /// **'Printer Test'**
  String get printerTest;

  /// No description provided for @csvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get csvExport;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @todayDonations.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Donations'**
  String get todayDonations;

  /// No description provided for @todayAmount.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Amount'**
  String get todayAmount;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Donation'**
  String get categoryGeneral;

  /// No description provided for @categoryPrasad.
  ///
  /// In en, this message translates to:
  /// **'Prasad'**
  String get categoryPrasad;

  /// No description provided for @categoryDecoration.
  ///
  /// In en, this message translates to:
  /// **'Decoration'**
  String get categoryDecoration;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @donorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Donor\'s Name'**
  String get donorNameLabel;

  /// No description provided for @amountAndPaymentMethodSection.
  ///
  /// In en, this message translates to:
  /// **'Amount & Payment Method'**
  String get amountAndPaymentMethodSection;

  /// No description provided for @amountRupees.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amountRupees;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @cashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get cashInHand;

  /// No description provided for @recurringDonorDescription.
  ///
  /// In en, this message translates to:
  /// **'This donor donates regularly'**
  String get recurringDonorDescription;

  /// No description provided for @amountReceivedNow.
  ///
  /// In en, this message translates to:
  /// **'Amount received now'**
  String get amountReceivedNow;

  /// No description provided for @amountLaterReceiptNow.
  ///
  /// In en, this message translates to:
  /// **'Amount to be received later (Give receipt now)'**
  String get amountLaterReceiptNow;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @newDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'New Donation'**
  String get newDonationTitle;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @enterNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter name or phone number...'**
  String get enterNameOrPhone;

  /// No description provided for @enterNamePhoneToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter donor name or phone number to search'**
  String get enterNamePhoneToSearch;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading information'**
  String get errorLoadingData;

  /// No description provided for @donationsCountFormat.
  ///
  /// In en, this message translates to:
  /// **'donations'**
  String get donationsCountFormat;

  /// No description provided for @totalDonationsFormat.
  ///
  /// In en, this message translates to:
  /// **'donations'**
  String get totalDonationsFormat;

  /// No description provided for @donationHistory.
  ///
  /// In en, this message translates to:
  /// **'Donation History'**
  String get donationHistory;

  /// No description provided for @receivedStatus.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @pleaseAddAtLeastOneDonation.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one donation'**
  String get pleaseAddAtLeastOneDonation;

  /// No description provided for @failedCount.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get failedCount;

  /// No description provided for @donationNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donationNumberFormat;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @paymentMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment Method *'**
  String get paymentMethodRequired;

  /// No description provided for @confirmPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Did the donor pay? This will be marked as received.'**
  String get confirmPaymentReceived;

  /// No description provided for @paymentMarkedReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment marked as received'**
  String get paymentMarkedReceived;

  /// No description provided for @donationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Donation cancelled'**
  String get donationCancelled;

  /// No description provided for @totalPendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Pending Amount'**
  String get totalPendingAmount;

  /// No description provided for @collectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get collectorLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @csvDownloaded.
  ///
  /// In en, this message translates to:
  /// **'CSV Downloaded'**
  String get csvDownloaded;

  /// No description provided for @csvDownload.
  ///
  /// In en, this message translates to:
  /// **'CSV Download'**
  String get csvDownload;

  /// No description provided for @printerFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Printer feature coming soon...'**
  String get printerFeatureComingSoon;

  /// No description provided for @provisionalReceiptOffline.
  ///
  /// In en, this message translates to:
  /// **'Provisional Receipt (Offline Mode)'**
  String get provisionalReceiptOffline;

  /// No description provided for @receiptNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt No.'**
  String get receiptNoLabel;

  /// No description provided for @donorLabel.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get donorLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @methodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodLabel;

  /// No description provided for @donationReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'DONATION RECEIPT'**
  String get donationReceiptTitle;

  /// No description provided for @receiptNoBilingual.
  ///
  /// In en, this message translates to:
  /// **'Receipt No.'**
  String get receiptNoBilingual;

  /// No description provided for @dateBilingual.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateBilingual;

  /// No description provided for @donorDetailsBilingual.
  ///
  /// In en, this message translates to:
  /// **'Donor Details'**
  String get donorDetailsBilingual;

  /// No description provided for @nameBilingual.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameBilingual;

  /// No description provided for @phoneBilingual.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneBilingual;

  /// No description provided for @addressBilingual.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressBilingual;

  /// No description provided for @amountBilingual.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountBilingual;

  /// No description provided for @paymentBilingual.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentBilingual;

  /// No description provided for @paymentReceivedBilingual.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceivedBilingual;

  /// No description provided for @paymentPendingBilingual.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPendingBilingual;

  /// No description provided for @cancelledBilingual.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledBilingual;

  /// No description provided for @registrationNo.
  ///
  /// In en, this message translates to:
  /// **'Registration No.'**
  String get registrationNo;

  /// No description provided for @officialsBilingual.
  ///
  /// In en, this message translates to:
  /// **'Officials'**
  String get officialsBilingual;

  /// No description provided for @presidentBilingual.
  ///
  /// In en, this message translates to:
  /// **'President'**
  String get presidentBilingual;

  /// No description provided for @vicePresidentBilingual.
  ///
  /// In en, this message translates to:
  /// **'Vice President'**
  String get vicePresidentBilingual;

  /// No description provided for @secretaryBilingual.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get secretaryBilingual;

  /// No description provided for @treasurerBilingual.
  ///
  /// In en, this message translates to:
  /// **'Treasurer'**
  String get treasurerBilingual;

  /// No description provided for @upiQrNotSet.
  ///
  /// In en, this message translates to:
  /// **'UPI QR Code not set'**
  String get upiQrNotSet;

  /// No description provided for @pleaseRequestAdmin.
  ///
  /// In en, this message translates to:
  /// **'Please request admin'**
  String get pleaseRequestAdmin;

  /// No description provided for @paymentAppsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Use Google Pay, PhonePe, Paytm'**
  String get paymentAppsInstruction;

  /// No description provided for @searchNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone'**
  String get searchNameEmailPhone;

  /// No description provided for @ganeshMandal.
  ///
  /// In en, this message translates to:
  /// **'Ganesh Mandal'**
  String get ganeshMandal;

  /// No description provided for @logoQrUpload.
  ///
  /// In en, this message translates to:
  /// **'Logo/QR Upload'**
  String get logoQrUpload;

  /// No description provided for @startTodaysCollection.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s collection'**
  String get startTodaysCollection;

  /// No description provided for @todaysCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todaysCollectionTitle;

  /// No description provided for @totalCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Collection'**
  String get totalCollectionTitle;

  /// No description provided for @topDonors.
  ///
  /// In en, this message translates to:
  /// **'Top Donors'**
  String get topDonors;

  /// No description provided for @upiCashBreakdown.
  ///
  /// In en, this message translates to:
  /// **'UPI | Cash'**
  String get upiCashBreakdown;

  /// No description provided for @donationStatsAverage.
  ///
  /// In en, this message translates to:
  /// **'donations | Average'**
  String get donationStatsAverage;

  /// No description provided for @welcomeMultilingual.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeMultilingual;

  /// No description provided for @continueInHindi.
  ///
  /// In en, this message translates to:
  /// **'Continue in Hindi'**
  String get continueInHindi;

  /// No description provided for @continueInMarathi.
  ///
  /// In en, this message translates to:
  /// **'Continue in Marathi'**
  String get continueInMarathi;

  /// No description provided for @languageChangedToHindi.
  ///
  /// In en, this message translates to:
  /// **'Language changed to Hindi'**
  String get languageChangedToHindi;

  /// No description provided for @languageChangedToMarathi.
  ///
  /// In en, this message translates to:
  /// **'Language changed to Marathi'**
  String get languageChangedToMarathi;

  /// No description provided for @paymentReceivedWithNote.
  ///
  /// In en, this message translates to:
  /// **'Payment Received (Amount received)'**
  String get paymentReceivedWithNote;

  /// No description provided for @paymentStatusPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Payment Status: Pending (To be paid later)'**
  String get paymentStatusPendingNote;

  /// No description provided for @amountRupeesRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹) *'**
  String get amountRupeesRequired;

  /// No description provided for @totalAmountValue.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountValue;

  /// No description provided for @csvDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV Downloaded'**
  String get csvDownloadSuccess;

  /// No description provided for @csvDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download CSV'**
  String get csvDownloadTooltip;

  /// No description provided for @donationsCount.
  ///
  /// In en, this message translates to:
  /// **'donations'**
  String get donationsCount;

  /// No description provided for @averageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageLabel;

  /// No description provided for @myPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'My Pending Payments'**
  String get myPendingPayments;

  /// No description provided for @overallCollection.
  ///
  /// In en, this message translates to:
  /// **'Overall Collection'**
  String get overallCollection;

  /// No description provided for @startCollectingDonations.
  ///
  /// In en, this message translates to:
  /// **'Start collecting donations today'**
  String get startCollectingDonations;

  /// No description provided for @todaysCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todaysCollection;

  /// No description provided for @scanQrToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to Pay'**
  String get scanQrToPay;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @csvExportInfo.
  ///
  /// In en, this message translates to:
  /// **'The CSV file will include all donations matching your selected filters. Leave filters empty to export all donations.'**
  String get csvExportInfo;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed. Please try again.'**
  String get printFailed;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @totalRecords.
  ///
  /// In en, this message translates to:
  /// **'Total Records'**
  String get totalRecords;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

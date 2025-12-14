# StoreKit Testing Setup Guide

This guide will help you set up and test in-app purchases locally in Xcode without needing App Store Connect.

## Step 1: Create StoreKit Configuration File

1. **In Xcode, go to:** File → New → File...
2. **Search for:** "StoreKit Configuration File"
3. **Name it:** `PhotoCleaner.storekit`
4. **Click:** Create

## Step 2: Add Products to StoreKit Configuration

Once the `.storekit` file is created, you'll see an editor. Add your subscription products:

### Add Weekly Subscription

1. Click the **+** button at the bottom left
2. Select **Add Auto-Renewable Subscription**
3. Configure:
   - **Reference Name:** Weekly Subscription
   - **Product ID:** `com.photocleaner.weekly`
   - **Price:** $4.99 USD
   - **Subscription Duration:** 1 Week
   - **Family Shareable:** No (unchecked)

### Add Free Trial to Weekly Subscription

1. Click on the Weekly Subscription you just created
2. In the right panel, find **Introductory Offers**
3. Click **+** to add an offer
4. Configure:
   - **Type:** Free Trial (Pay Nothing)
   - **Duration:** 3 Days
   - **Number of Periods:** 1

### Add Yearly Subscription

1. Click the **+** button again
2. Select **Add Auto-Renewable Subscription**
3. Configure:
   - **Reference Name:** Yearly Subscription
   - **Product ID:** `com.photocleaner.yearly`
   - **Price:** $29.99 USD
   - **Subscription Duration:** 1 Year
   - **Family Shareable:** No (unchecked)

### Important: Add Subscription Group

Both subscriptions need to be in the same subscription group:

1. Select the Weekly subscription
2. In the **Subscription Group** field, enter: `photocleaner_premium`
3. Select the Yearly subscription
4. Use the same group: `photocleaner_premium`

## Step 3: Configure Product Localization (Optional)

For each product, you can add localized descriptions:

1. Select a product
2. In the right panel, find **Localizations**
3. Click **+** to add a locale
4. Fill in:
   - **Display Name:** PhotoCleaner Premium (Weekly/Yearly)
   - **Description:** Unlimited photo cleaning and organization

## Step 4: Enable StoreKit Testing in Xcode

### Option A: Use Scheme Configuration (Recommended)

1. **Edit your scheme:** Product → Scheme → Edit Scheme... (or ⌘<)
2. **Select:** Run (in the left sidebar)
3. **Go to:** Options tab
4. **Under StoreKit Configuration:** Select `PhotoCleaner.storekit`
5. **Click:** Close

### Option B: Set Default in Project Settings

1. Open your project settings (click on PhotoCleaner in the Project Navigator)
2. Select the **PhotoCleaner** target
3. Go to the **Signing & Capabilities** tab
4. If you see StoreKit Testing, enable it and select `PhotoCleaner.storekit`

## Step 5: Test Purchases

### Run the App

1. **Build and run** on the simulator or device
2. Navigate to the paywall
3. Click on a subscription plan
4. Click "Subscribe"

### StoreKit Testing Sheet

When you attempt a purchase, you'll see a **StoreKit Testing Sheet** that shows:
- Product details
- Price
- Subscription period
- Free trial information (if applicable)

### Test Options

In the sheet, you can:
- **Approve Purchase** - Simulates successful purchase
- **Decline Purchase** - Simulates user cancellation
- **Ask to Buy** - Simulates parental approval requirement

### View Transactions

1. While the app is running, go to: **Debug → StoreKit → Manage Transactions**
2. You'll see all test transactions
3. You can:
   - Refund purchases
   - Expire subscriptions
   - Clear purchase history
   - Speed up subscription renewals

## Step 6: Test Different Scenarios

### Test Free Trial

1. Purchase the weekly subscription
2. You'll see "3 days free trial" in the sheet
3. Approve the purchase
4. In **Manage Transactions**, you can:
   - Speed up time to expire the trial
   - Test renewal behavior

### Test Subscription Renewal

1. Go to **Debug → StoreKit → Editor → Time Rate**
2. Select a faster time rate (e.g., "1 minute = 1 hour")
3. This speeds up subscription renewals for testing

### Test Restore Purchases

1. Go to **Debug → StoreKit → Manage Transactions**
2. Click **Clear Purchase History**
3. In your app, tap "Restore Purchases"
4. Verify that subscriptions are restored

### Test Different Prices/Locales

1. In the `.storekit` file, you can add multiple price points
2. Test with different App Store regions
3. Simulator: Settings → General → Language & Region

## Step 7: Debug Common Issues

### Products Not Loading

If `subscriptionManager.products` is empty:

1. Check that product IDs match exactly:
   - `com.photocleaner.weekly`
   - `com.photocleaner.yearly`
2. Verify StoreKit configuration is enabled in scheme
3. Check console for errors: `Failed to load products: [error]`

### Purchases Not Working

1. Make sure you're running on a real device or simulator (not Preview)
2. Check that StoreKit configuration file is selected
3. Verify subscription group is set correctly

### Display Prices Not Showing

1. Products must be loaded first: `await subscriptionManager.loadProducts()`
2. Check that `subscriptionManager.products` is not empty
3. Verify you're using `.formattedPrice(from: product)` not hardcoded prices

## Step 8: Test on Real Device (Optional)

### Using TestFlight (Before App Store Connect Setup)

You can test locally on device with the StoreKit file:

1. Connect your device
2. Select your device as the run destination
3. Build and run
4. StoreKit testing will work the same as simulator

### Using Sandbox Testing (After App Store Connect Setup)

1. Create products in App Store Connect
2. Add test users in App Store Connect → Users and Access → Sandbox Testers
3. On device: Settings → App Store → Sandbox Account → Sign in with test user
4. Purchases will use App Store Connect products

## StoreKit File Example

Your `PhotoCleaner.storekit` file should look like this:

```json
{
  "identifier" : "PhotoCleaner",
  "nonRenewingSubscriptions" : [],
  "products" : [],
  "settings" : {
    "_failTransactionsEnabled" : false,
    "_storeKitErrors" : []
  },
  "subscriptionGroups" : [
    {
      "id" : "photocleaner_premium",
      "localizations" : [],
      "name" : "PhotoCleaner Premium",
      "subscriptions" : [
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "4.99",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "weekly_sub",
          "introductoryOffer" : {
            "internalID" : "weekly_trial",
            "numberOfPeriods" : 1,
            "paymentMode" : "free",
            "subscriptionPeriod" : "P3D"
          },
          "localizations" : [
            {
              "description" : "Unlimited photo cleaning",
              "displayName" : "Weekly Premium",
              "locale" : "en_US"
            }
          ],
          "productID" : "com.photocleaner.weekly",
          "recurringSubscriptionPeriod" : "P1W",
          "referenceName" : "Weekly Subscription",
          "subscriptionGroupID" : "photocleaner_premium",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "29.99",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "yearly_sub",
          "localizations" : [
            {
              "description" : "Unlimited photo cleaning - Best Value!",
              "displayName" : "Yearly Premium",
              "locale" : "en_US"
            }
          ],
          "productID" : "com.photocleaner.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "referenceName" : "Yearly Subscription",
          "subscriptionGroupID" : "photocleaner_premium",
          "type" : "RecurringSubscription"
        }
      ]
    }
  ],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
```

## Troubleshooting

### "Product not found" error
- Verify product IDs are exactly `com.photocleaner.weekly` and `com.photocleaner.yearly`
- Check that StoreKit file is enabled in scheme

### Prices showing as "$4.99" instead of localized
- Products loaded successfully if you see this
- Dynamic pricing is working correctly

### Free trial not showing
- Check introductory offer is configured in .storekit file
- Verify offer type is "Free Trial"

### Can't test renewals
- Use Debug → StoreKit → Editor → Time Rate
- Set to faster rate to speed up renewals

## Next Steps

Once local testing is working:

1. **Set up App Store Connect:**
   - Create your app listing
   - Add the same product IDs
   - Configure subscriptions and trials

2. **TestFlight Testing:**
   - Upload a build
   - Test with real App Store sandbox
   - Invite beta testers

3. **Production:**
   - Submit for App Review
   - Launch subscriptions

## Resources

- [Apple StoreKit Testing Documentation](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_in_xcode)
- [Managing StoreKit Transactions](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode#Manage-transactions)

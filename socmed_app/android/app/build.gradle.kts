plugins {
    id("com.android.application")
    id("kotlin-android")
    // Idagdag itong line na ito sa loob ng plugins block:
    id("com.google.gms.google-services")
}

// ... (yung ibang part ng build.gradle.kts mo dito sa gitna)

dependencies {
    // Siguraduhin na nandoon ang Firebase BoM para sa version management
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
}
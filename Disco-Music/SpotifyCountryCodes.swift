//
//  SpotifyCountryCodes.swift
//  Disco-Music
//
//  Created by Parissa Teli on 11/30/25.
//
//  Contains full Spotify-supported market codes.
//  Source: Spotify Web API documentation
//  Generated with ChatGPT

import Foundation

struct SpotifyCountryCodes {

    //  Full mapping of country names → Spotify market codes.
    // Uses Spotify’s official set of supported markets (ISO 3166-1 alpha-2).
    static let mapping: [String: String] = [

        // North America
        "United States": "US",
        "Canada": "CA",
        "Mexico": "MX",

        // South America
        "Argentina": "AR",
        "Bolivia": "BO",
        "Brazil": "BR",
        "Chile": "CL",
        "Colombia": "CO",
        "Costa Rica": "CR",
        "Dominican Republic": "DO",
        "Ecuador": "EC",
        "El Salvador": "SV",
        "Guatemala": "GT",
        "Honduras": "HN",
        "Nicaragua": "NI",
        "Panama": "PA",
        "Paraguay": "PY",
        "Peru": "PE",
        "Uruguay": "UY",

        // Europe
        "Austria": "AT",
        "Belgium": "BE",
        "Bulgaria": "BG",
        "Croatia": "HR",
        "Cyprus": "CY",
        "Czech Republic": "CZ",
        "Denmark": "DK",
        "Estonia": "EE",
        "Finland": "FI",
        "France": "FR",
        "Germany": "DE",
        "Greece": "GR",
        "Hungary": "HU",
        "Iceland": "IS",
        "Ireland": "IE",
        "Italy": "IT",
        "Latvia": "LV",
        "Liechtenstein": "LI",
        "Lithuania": "LT",
        "Luxembourg": "LU",
        "Malta": "MT",
        "Netherlands": "NL",
        "Norway": "NO",
        "Poland": "PL",
        "Portugal": "PT",
        "Romania": "RO",
        "Slovakia": "SK",
        "Slovenia": "SI",
        "Spain": "ES",
        "Sweden": "SE",
        "Switzerland": "CH",
        "United Kingdom": "GB",

        // Middle East & North Africa
        "Algeria": "DZ",
        "Bahrain": "BH",
        "Egypt": "EG",
        "Israel": "IL",
        "Jordan": "JO",
        "Kuwait": "KW",
        "Lebanon": "LB",
        "Morocco": "MA",
        "Oman": "OM",
        "Qatar": "QA",
        "Saudi Arabia": "SA",
        "Tunisia": "TN",
        "United Arab Emirates": "AE",

        // Sub-Saharan Africa
        "Benin": "BJ",
        "Botswana": "BW",
        "Burkina Faso": "BF",
        "Cape Verde": "CV",
        "Chad": "TD",
        "Eswatini": "SZ",
        "Gambia": "GM",
        "Ghana": "GH",
        "Kenya": "KE",
        "Lesotho": "LS",
        "Liberia": "LR",
        "Madagascar": "MG",
        "Malawi": "MW",
        "Mauritania": "MR",
        "Mauritius": "MU",
        "Mozambique": "MZ",
        "Namibia": "NA",
        "Niger": "NE",
        "Nigeria": "NG",
        "Rwanda": "RW",
        "Senegal": "SN",
        "Seychelles": "SC",
        "Sierra Leone": "SL",
        "South Africa": "ZA",
        "Tanzania": "TZ",
        "Togo": "TG",
        "Uganda": "UG",
        "Zambia": "ZM",
        "Zimbabwe": "ZW",

        // Asia
        "Bangladesh": "BD",
        "Brunei": "BN",
        "Cambodia": "KH",
        "Hong Kong": "HK",
        "India": "IN",
        "Indonesia": "ID",
        "Japan": "JP",
        "Kazakhstan": "KZ",
        "Kyrgyzstan": "KG",
        "Laos": "LA",
        "Macau": "MO",
        "Malaysia": "MY",
        "Maldives": "MV",
        "Mongolia": "MN",
        "Nepal": "NP",
        "Pakistan": "PK",
        "Philippines": "PH",
        "Singapore": "SG",
        "South Korea": "KR",
        "Sri Lanka": "LK",
        "Taiwan": "TW",
        "Thailand": "TH",
        "Vietnam": "VN",

        // Oceania
        "Australia": "AU",
        "New Zealand": "NZ",
        "Fiji": "FJ",
        "Papua New Guinea": "PG",
        "Samoa": "WS",
        "Tonga": "TO",
        "Vanuatu": "VU"
    ]

    // Returns Spotify market code for a given country name.
    // Falls back to "US" if country is not recognized.
    static func code(for countryName: String) -> String {
        mapping[countryName] ?? "US"
    }
}

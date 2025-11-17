//
//  OnboardingView.swift
//  Disco-Music
//
//  Created by Heather Meade on 11/17/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var name: String = ""
    @State private var country: String = ""
    @Binding var showOnboarding: Bool
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                WelcomePage().tag(0)
                IntroductionPage(name: $name){
                    currentPage = 2
                }.tag(1)
                LocationPage(country: $country) {
                    currentPage = 3
                }.tag(2)
                ConceptsPage().tag(3)
                FeaturePage {
                    showOnboarding = false
                }.tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .ignoresSafeArea()
        }
    }
}

struct WelcomePage: View {
    @State private var animateText = false
    var body : some View {
        VStack() {
            Spacer()
            Text("Welcome")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(LinearGradient(
                    colors: [
                        Color(red: 81/255, green: 175/255, blue: 134/255),
                        Color(red: 68/255, green: 148/255, blue: 151/255)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .scaleEffect(x: animateText ? 1 : 0, y: 1, anchor: .leading)
                .opacity(animateText ? 1 : 0)
                .animation(.easeOut(duration: 0.9), value: animateText)
                .padding()
            Text("Discover music from every region of the world.")
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [
            Color(red: 33/255, green: 33/255, blue: 70/255),
            Color(red: 15/255, green: 15/255, blue: 21/255)],
                           startPoint: .top, endPoint: .bottom)
        )
        .onAppear {
            animateText = true
        }
    }
}

struct IntroductionPage: View {
    @Binding var name: String
    var onContinue: () -> Void
    @FocusState private var isNameFieldFocused: Bool
    var body: some View {
        VStack {
            Spacer()
            Text("What's your name?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("We'll use this to personalize your experience.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            TextField("Name", text: $name)
                .padding(14)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundColor(.white)
                .background(Color.white.opacity(0.08).cornerRadius(14)
                .focused($isNameFieldFocused))
                .padding(.horizontal, 32)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 81/255, green: 175/255, blue: 134/255),
                                Color(red: 68/255, green: 148/255, blue: 151/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 32)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, 50)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [
            Color(red: 33/255, green: 33/255, blue: 70/255),
            Color(red: 15/255, green: 15/255, blue: 21/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}

struct LocationPage: View {
    @Binding var country: String
    var onContinue: () -> Void
    let countries = Locale.isoRegionCodes.compactMap{ Locale.current.localizedString(forRegionCode: $0) }.sorted()
    var body: some View {
        VStack {
            Spacer()
            Text("Where are you from?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("We'll use this to show you music from your home and around the world.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            Menu {
                ForEach(countries, id: \.self) { item in
                    Button(item) {
                        country = item
                    }
                }
            } label: {
                HStack {
                    Text(country.isEmpty ? "Select your country" : country)
                        .foregroundColor(country.isEmpty ? .white.opacity(0.5) : .white)
                    
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body.bold())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 81/255, green: 175/255, blue: 134/255),
                                Color(red: 68/255, green: 148/255, blue: 151/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .foregroundColor(.white)
                    .opacity(country.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 32)
            .disabled(country.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, 50)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [
            Color(red: 33/255, green: 33/255, blue: 70/255),
            Color(red: 15/255, green: 15/255, blue: 21/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}

struct ConceptsPage: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Discover music from every corner of the world.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("Tap a country, explore its genres, and listen to playlists inspired by local sounds.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                VStack(spacing: 16) {
                    // Icon + label
                    HStack(spacing: 10) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 81/255, green: 175/255, blue: 134/255))
                        
                        Text("World Map")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text("Zoom into any region to hear what people are listening to there right now.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                    
                    // Little “pills” for genres / regions
                    HStack(spacing: 8) {
                        conceptPill(text: "Afrobeat")
                        conceptPill(text: "City Pop")
                        conceptPill(text: "Samba")
                        conceptPill(text: "Flamenco")
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "scope",
                    title: "Explore",
                    subtitle: "Tap a country on the map to discover its unique sounds."
                )
                featureRow(
                    icon: "book.fill",
                    title: "Learn",
                    subtitle: "Get quick context on genres, culture, and history."
                )
                featureRow(
                    icon: "music.note.list",
                    title: "Generate Playlists",
                    subtitle: "Create Spotify-ready playlists inspired by each region."
                )
            }
            .padding(.horizontal, 32)
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [
            Color(red: 33/255, green: 33/255, blue: 70/255),
            Color(red: 15/255, green: 15/255, blue: 21/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
    
    private func conceptPill(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10))
            .cornerRadius(999)
            .foregroundColor(.white)
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 81/255, green: 175/255, blue: 134/255))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
            }
            
            Spacer()
        }
    }
    
}

struct FeaturePage: View {
    var onContinue: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Text("What you can do with Disco")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text("A world of music in one app. Here's how Disco helps you explore, learn, and listen.")
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            VStack(spacing: 16) {
                featureCard(
                    icon: "globe.americas.fill",
                    title: "Explore the map",
                    description: "Tap countries and regions to discover local genres, sounds, and trends."
                )
                
                featureCard(
                    icon: "lightbulb.fill",
                    title: "Learn the story",
                    description: "Get quick context about each region’s musical history and culture."
                )
                
                featureCard(
                    icon: "music.note.list",
                    title: "Generate playlists",
                    description: "Turn your discoveries into ready-to-play Spotify playlists in a tap."
                )
            }
            .padding(.horizontal, 24)
            Spacer()
            Button(action: onContinue) {
                Text("Let’s go")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 81/255, green: 175/255, blue: 134/255),
                                Color(red: 68/255, green: 148/255, blue: 151/255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)

            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [
            Color(red: 33/255, green: 33/255, blue: 70/255),
            Color(red: 15/255, green: 15/255, blue: 21/255)],
                           startPoint: .top, endPoint: .bottom)
        )
    }
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 81/255, green: 175/255, blue: 134/255))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
    
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}

//
//  SplashView.swift
//  PresentationGenerator
//
//  Splash screen shown on app launch
//

import SwiftUI

struct SplashView: View {
    @State private var isVisible = true
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 20) {
                // Logo/Image placeholder
                Image(systemName: "book.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .opacity(0.9)
                
                // Title
                VStack(spacing: 8) {
                    Text("Presentation Maker")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("for Don Luciano")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("by Benedetto Proietti")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)
                }
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .frame(width: 500, height: 350)
        .onAppear {
            // Fade in animation
            withAnimation(.easeIn(duration: 0.5)) {
                isVisible = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isVisible = false
                }
                
                // Call completion after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

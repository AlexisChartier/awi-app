//
//  GameCardView.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct GameCardView: View {
    let game: Jeu
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 4)

            VStack {
                if let imageURL = game.image, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let img):
                            img
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                        case .failure(_):
                            Image(systemName: "xmark.circle")
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Pas d'URL
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.gray)
                }
                Text(game.nom)
                    .font(.headline)
                    .padding(.bottom, 4)
                if let editeur = game.editeur {
                    Text("Éditeur: \(editeur)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            if isSelected {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .padding(6)
            }
        }
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

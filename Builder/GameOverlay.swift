//
//  GameOverlay.swift
//  Builder
//
//  Created by Max Siebengartner on 28/8/2024.
//

import Foundation
import SwiftUI

struct GameOverlayIPhone : View {
    @EnvironmentObject var game: BuildingGame
    @State var materialMenuShowing: Bool = false
    @State var gravitySliderShowing: Bool = false
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            game.menuOpen.toggle()
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: geometry.size.width * 0.08, height: geometry.size.width * 0.08)
                            .padding(8)
                            .background {
                                Color.white
                            }
                            .clipShape(Circle())
                            .shadow(radius: 8)
                            .padding(.horizontal, 30)
                            .rotationEffect(game.menuOpen ? Angle(degrees: 60) : Angle.zero)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(.white)
                            .frame(width: geometry.size.width * 0.12, height: geometry.size.width * 0.08 + (game.menuOpen ? geometry.size.width / 3 : 0))
                            .offset(y: (game.menuOpen ? geometry.size.width / 3 : 0) / 2)
                            .overlay {
                                Group {
                                    Button {
                                        game.loadVisuals.toggle()
                                    } label: {
                                        Image(systemName: "batteryblock" + (game.loadVisuals ? ".fill" : ""))
                                            .resizable()
                                            .frame(width: geometry.size.width * 0.06, height: geometry.size.width * 0.05)
                                            .foregroundStyle(LinearGradient(colors: (game.loadVisuals ? [.red, .yellow, .green] : [.blue]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .offset(y: (game.menuOpen ? geometry.size.width / 3 : 0) / 3)
                                    .opacity(game.menuOpen ? 1 : 0)
                                    Button {
                                        gravitySliderShowing.toggle()
                                    } label: {
                                        Image(systemName: "arrow.down.app" + (gravitySliderShowing ? ".fill" : ""))
                                            .resizable()
                                            .frame(width: geometry.size.width * 0.06, height: geometry.size.width * 0.06)
                                    }
                                    .offset(y: (game.menuOpen ? geometry.size.width / 1.6 : 0) / 3)
                                    .opacity(game.menuOpen ? 1 : 0)
                                    .overlay {
                                        if gravitySliderShowing && game.menuOpen {
                                            VStack {
                                                Text("Gravity \(game.gravity)")
                                                    .foregroundStyle(.black)
                                                Slider(value: $game.gravity, in: 0...20)
                                            }
                                            .frame(width: 100, height: 50)
                                            .padding()
                                            .background {
                                                Color.white
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .offset(x: -100, y: (game.menuOpen ? geometry.size.width / 1.6 : 0) / 3)
                                        }
                                    }
                                }
                            }
                    }
                }
                Spacer()
                HStack {
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height / 5, alignment: .center)
                .background {
                    Color.black.opacity(0.5)
                }
                .offset(y: materialMenuShowing ? geometry.safeAreaInsets.bottom : geometry.size.height / 5 + geometry.safeAreaInsets.bottom)
            }
        }
    }
}
enum Tabs: String, CaseIterable, Identifiable {
    
    var id: Self {
        return self
    }
    
    case Options = "slider.horizontal.3"
    case Inspector = "magnifyingglass"
    
    func name() -> String {
        switch self {
        case .Options:
            return "Options"
        case .Inspector:
            return "Inspector"
        }
    }
}
struct IpadDetail: View {
    @EnvironmentObject var game: BuildingGame
    @State var menuOffx: CGFloat = 0
    @State var dragOffx: CGFloat? = nil
    @State var tab = Tabs.Options
    var body: some View {
        GeometryReader { geometry in
            if !game.menuOpen {
                menuOpenButton(geometry)
                    .padding()
            }
            VStack {
                HStack {
                    ForEach(Tabs.allCases) { i in
                        Button {
                            tab = i
                        } label: {
                            Image(systemName: i.rawValue)
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundStyle(tab == i ? .blue : .gray)
                        }
                        .padding(.horizontal)
                    }
                    .pickerStyle(.segmented)
                }
                .padding([.horizontal, .bottom], 5)
                .padding(.top, 25)
                Divider()
                
                if tab == .Options {
                    List {
                        Section("View") {
                            Toggle("Show Load Visuals", isOn: $game.loadVisuals)
                        }
                        Section("Physics") {
                            VStack {
                                Text("Gravity \(game.gravity)")
                                Slider(value: $game.gravity, in: 0...20)
                            }
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    
                }
                Spacer()
            }
            .frame(width: geometry.size.width / 5, height: geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom + geometry.size.height)
            .ignoresSafeArea()
            .background {
                Color.white
            }
            .offset(x: menuOffx, y: -geometry.safeAreaInsets.top)
            .onAppear {
                menuOffx = -geometry.size.width / 5
            }
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged({ value in
                    let min = -geometry.size.width / 5
                    if dragOffx == nil {
                        dragOffx = value.location.x + min
                    }
                    menuOffx = clamp(min: min, max: 0, value: value.location.x + min - (dragOffx ?? 0))
                })
                    .onEnded { value in
                        dragOffx = nil
                        let min = -geometry.size.width / 5
                        if menuOffx < min / 2 || value.velocity.width < -10 {
                            game.menuOpen = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                menuOffx = -geometry.size.width / 5
                            }
                            
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                menuOffx = 0
                            }
                            game.menuOpen = true
                        }
                    })
        }
    }
    func menuOpenButton(_ geometry: GeometryProxy) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) {
                menuOffx = 0
                game.menuOpen = true
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .resizable()
                .frame(width: geometry.size.height * 0.025, height: geometry.size.height * 0.02)
                .padding()
                .background {
                    Color.white
                }
                .clipShape(Circle())
        }
    }
}
#Preview {
    ContentView()
}

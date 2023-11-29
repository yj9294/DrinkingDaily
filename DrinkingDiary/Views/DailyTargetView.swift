//
//  DailyTargetView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/3.
//

import SwiftUI
import ComposableArchitecture

struct DailyTarget: Reducer {
    struct State: Equatable {
        @BindingState var total: Int
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pop
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            return .none
        }
    }
}

struct DailyTargetView: View {
    let store: StoreOf<DailyTarget>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                VStack{
                    HStack{ Spacer() }
                    VStack(spacing: 0){
                        ContentView(total: viewStore.total)
                        ActionView(total: viewStore.$total)
                    }
                }.cornerRadius(12).padding(.horizontal, 20).padding(.top, 40)
                Spacer()
            }.toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        viewStore.send(.pop)
                    }, label: {
                        Image("back")
                    })
                }
            })
        }.background.navigationTitle(Text("Water Intake")).navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden()
    }
    struct ContentView: View {
        let total: Int
        var body: some View {
            VStack{
                Image("drink_drop")
                Text("Your Daily water goal: \(total)ml").font(.system(size: 12.0)).foregroundStyle(Color("#5790B1"))
                HStack {
                    Spacer()
                    Text("\(total)ml").font(.title).foregroundStyle(.white)
                    Spacer()
                }.padding(.vertical, 13).background(.linearGradient(colors: [Color("#42CDF8"), Color("#084D99")], startPoint: .leading, endPoint: .trailing)).cornerRadius(8).padding(.horizontal, 70).padding(.top, 15)
            }.padding(.vertical, 20).background(Image("drink_goal_bg").resizable())
        }
    }
    
    struct ActionView: View {
        @Binding var total: Int
        @State private var location: CGPoint = CGPoint(x: 25, y: 25)
        var progress: Double {
            Double(total) / 4000.0
        }
        var body: some View {
            VStack{
                HStack{
                    Spacer()
                    GeometryReader{ pr in
                        ZStack{
                            HStack(spacing: 0) {
                                Button(action: {
                                    total -= 100
                                    total = total <= 100 ? 100 : total
                                }, label: {
                                    Image("drink_goal_-").frame(width: 50, height: 50)
                                }).background(Color("#41C5FF"))
                                HStack{
                                    GeometryReader{ proxy in
                                        ZStack {
                                            let width = (proxy.size.width - 20)
                                            let x =  width * progress - 25 <= 0 ? 0 : width * progress - 25
                                            let nx = ((x + 25) > width) ? width : (x+25)
                                            HStack(spacing:0){
                                                LinearGradient(colors: [Color("#41C5FF"), Color("#00A2FF")], startPoint: .leading, endPoint: .trailing).frame(width: nx)
                                                Color("#E5EDF0")
                                            }
                                            HStack(spacing:0){
                                                Color.clear.frame(width: x)
                                                Image("drink_point").gesture(DragGesture(minimumDistance: 1, coordinateSpace: .local).onChanged { value in
                                                    let move = value.location.x - location.x
                                                    if move < 0 {
                                                        let pro = abs(move) / proxy.size.width
                                                        total = total - (Int(pro * 4000)  - Int(pro * 4000) % 100)
                                                        total = total <= 100 ? 100 : total
                                                    } else {
                                                        let pro = abs(move) / proxy.size.width
                                                        total = total + (Int(pro * 4000)  - Int(pro * 4000) % 100)
                                                        total = total >= 4000 ? 4000 : total
                                                    }
                                                }).position(location)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                Button(action: {
                                    total += 100
                                    total = total >= 4000 ? 4000 : total
                                }, label: {
                                    Image("drink_goal_+")
                                }).frame(width: 50, height: 50)
                            }.background(Color("#E5EDF0"))
                        }
                    }.frame(height: 50).cornerRadius(25)
                    Spacer()
                }.padding(.vertical, 24)
            }.padding(.horizontal, 20).background(.white).onChange(of: total) { _ in
                simpleSuccess()
            }
        }
        
        func simpleSuccess() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
    }

}

#Preview {
    NavigationView{
        DailyTargetView(store: Store.init(initialState: DailyTarget.State(total: 4000), reducer: {
            DailyTarget()
        }))
    }
}

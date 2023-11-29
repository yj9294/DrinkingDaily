//
//  DrinkView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

struct Drink: Reducer {
    struct State: Equatable {
        static func == (lhs: Drink.State, rhs: Drink.State) -> Bool {
            lhs.dailyGoal == rhs.dailyGoal &&
            lhs.dailyDrink == rhs.dailyDrink &&
            lhs.ad == rhs.ad
        }
        @UserDefault(key: "drink:goal")
        var dailyGoal: Int?
        @UserDefault(key: "record:list")
        var recordList: [Record.Model]?
        
        var ad: GADNativeViewModel = .none
        
        var dailyDrink: Int {
            (recordList ?? []).filter { model in
                model.day == Date().day
            }.map({
                $0.ml
            }).reduce(0, +)
        }
        var progress: Double {
            Double(dailyDrink) / Double(dailyGoal ?? 2000)
        }
        var goal: Int {
            dailyGoal ?? 2000
        }
    }
    enum Action: Equatable {
        case dailyTargetButtonTapped
        case recordButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DrinkView: View {
    let store: StoreOf<Drink>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                if viewStore.ad != .none {
                    HStack{
                        GADNativeView(model: viewStore.ad)
                    }.frame(height: 124).padding(.horizontal, 20).padding(.top, 20)
                }
                VStack{
                    Image("drink_icon").resizable().scaledToFit()
                    HStack{
                        ContentProgressView(progress: viewStore.progress)
                        Spacer()
                        VStack{
                            ContentDailyGoalView(goal: viewStore.dailyGoal) {
                                viewStore.send(.dailyTargetButtonTapped)
                            }
                            ContentRecordButton {
                                viewStore.send(.recordButtonTapped)
                            }
                        }.padding(.leading, 30).padding(.trailing, 18)
                    }.padding(.all, 16)
                    HStack{
                        Spacer()
                    }
                }.background(.white).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.top, 20).padding(.horizontal, 20)
                Spacer()
            }.background.navigationBarTitle(.drink)
        }
    }
    
    struct ContentProgressView: View {
        let progress: Double
        var body: some View {
            ZStack{
                Image("drink_animation")
                CircleView(progress: progress).frame(width: 120, height: 120)
                Text("\(Int(progress*100))%").font(.system(size: 27))
            }
        }
    }
    
    struct ContentDailyGoalView: View {
        let goal: Int?
        let action: ()->Void
        var body: some View {
            Button(action: action, label: {
                VStack(alignment: .leading, spacing: 8){
                    Text("Daily Target").foregroundColor(Color("#A5B7C4")).font(.system(size: 12.0))
                    HStack{
                        Text("\(goal ?? 2000)ml").font(.system(size: 18)).foregroundStyle(.black)
                        Spacer()
                        Image("drink_edit")
                    }
                }
            }).padding(.vertical, 8).padding(.horizontal, 13).background(Color("#D7F6FF").cornerRadius(16))
        }
    }
    
    struct ContentRecordButton: View {
        let action: ()->Void
        var body: some View {
            Button(action: action, label: {
                HStack{
                    Spacer()
                    Image("drink_+")
                    Text("Record").foregroundStyle(.white)
                    Spacer()
                }
            }).padding(.vertical, 13).background(.linearGradient(colors: [Color("#41C5FF"), Color("#00A2FF")], startPoint: .leading, endPoint: .trailing)).cornerRadius(33)
        }
    }
}


struct CircleView: UIViewRepresentable {
    let progress: Double

    func makeUIView(context: Context) -> some UIView {
        return UICircleProgressView()
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let view = uiView as? UICircleProgressView {
            view.setProgress(Int(progress * 1000.0))
        }
    }
    
    class UICircleProgressView: UIView {
        // 灰色静态圆环
        var staticLayer: CAShapeLayer!
        // 进度可变圆环
        var arcLayer: CAShapeLayer!
        
        // 为了显示更精细，进度范围设置为 0 ~ 1000
        var progress = 0

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setProgress(_ progress: Int) {
            self.progress = progress
            setNeedsDisplay()
        }
        
        override func draw(_ rect: CGRect) {
            if staticLayer == nil {
                staticLayer = createLayer(progress, 8, UIColor(named: "#63BCFF") ?? .blue)
            }
            self.layer.addSublayer(staticLayer)
            if arcLayer != nil {
                arcLayer.removeFromSuperlayer()
            }
            arcLayer = createLayer(progress, 4, UIColor(named: "#9063FF") ?? .red)
            self.layer.addSublayer(arcLayer)
        }
        
        private func createLayer(_ progress: Int, _ width: Int, _ color: UIColor) -> CAShapeLayer {
            let endAngle = -CGFloat.pi / 2 + (CGFloat.pi * 2) * CGFloat(progress) / 1000
            let layer = CAShapeLayer()
            layer.lineWidth = CGFloat(width)
            layer.strokeColor = color.cgColor
            layer.fillColor = UIColor.clear.cgColor
//            layer.lineCap = .round
            var radius = self.bounds.width / 2 - layer.lineWidth
            if width == 4 {
                radius = radius - 2
            }
            let path = UIBezierPath.init(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: radius, startAngle: -CGFloat.pi / 2, endAngle: endAngle, clockwise: true)
            layer.path = path.cgPath
            return layer
        }
    }
}

#Preview {
    NavigationView(content: {
        DrinkView(store: Store.init(initialState: Drink.State(), reducer: {
            Drink()
        }))
    })
}

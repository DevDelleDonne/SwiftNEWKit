//
//  Created by Ming on 11/6/2022.
//

import SwiftUI
import SwiftVB

#if os(iOS)
import Drops
#endif
 
@available(iOS 14, watchOS 7.0, macOS 11.0, *)
public struct SwiftNEW: View {
    @AppStorage("version") var version = 1.0
    @AppStorage("build") var build: Double = 1
    
    @State var items: [Vmodel] = []
    @State var loading = true
    @State var historySheet: Bool = false
    
    @Binding var show: Bool
    @Binding var align: HorizontalAlignment
    @Binding var color: Color
    @Binding var size: String
    @Binding var labelColor: Color
    @Binding var label: String
    @Binding var labelImage: String
    @Binding var history: Bool
    @Binding var data: String
    @Binding var showDrop: Bool

    public init( show: Binding<Bool>, align: Binding<HorizontalAlignment>, color: Binding<Color>, size: Binding<String>, labelColor: Binding<Color>, label: Binding<String>, labelImage: Binding<String>, history: Binding<Bool>, data: Binding<String>, showDrop: Binding<Bool>) {
        _show = show
        _align = align
        _color = color
        _size = size
        _labelColor = labelColor
        _label = label
        _labelImage = labelImage
        _history = history
        _data = data
        _showDrop = showDrop
        compareVersion()
    }
 
    public var body: some View {
        Button(action: {
            if showDrop {
                #if os(iOS)
                drop()
                #endif
            } else {
                show = true
            }
        }) {
            if size == "mini" {
                Label(label, systemImage: labelImage)
            }
            else if size == "normal" {
                Label(label, systemImage: labelImage)
                    .frame(width: 300, height: 50)
                    #if os(iOS)
                    .foregroundColor(labelColor)
                    .background(color)
                    .cornerRadius(15)
                    #endif
            }
        }
        .sheet(isPresented: $show) {
            sheetCurrent
                .sheet(isPresented: $historySheet) {
                    sheetHistory
                }
        }
    }
    
    public var sheetCurrent: some View {
        VStack(alignment: align) {
            Spacer()
            AppIcon()
                .clipShape(RoundedRectangle(cornerRadius: 19))
                
            Text("What's New in").bold().font(.largeTitle)
            Text("Version \(Bundle.versionBuild)").bold().font(.title).foregroundColor(.secondary)
           
            Spacer()
            if loading {
                ProgressView()
            } else {
                ScrollView(showsIndicators: false) {
                    ForEach(items, id: \.self) { item in
                        if item.version == Bundle.version {
                            ForEach(item.new, id: \.self) { new in
                                HStack {
                                    ZStack {
                                        color
                                        Image(systemName: new.icon)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 50, height:50)
                                    .cornerRadius(15)
                                    .padding(.trailing)
                                    VStack(alignment: .leading) {
                                        Text(new.title).font(.headline).lineLimit(1)
                                        Text(new.subtitle).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                                        Text(new.body).font(.caption).foregroundColor(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                }.padding(.bottom)
                            }
                        }
                    }
                }.frame(width: 300)
                .frame(maxHeight: 450)
            }
            Spacer()
            if history {
                Button(action: { historySheet = true }) {
                    HStack {
                        Text("Show History")
                        Image(systemName: "arrow.up.bin")
                    }.font(.body)
                }.foregroundColor(color)
            }
            Button(action: { show = false }) {
                HStack{
                    Text("Continue").bold()
                    Image(systemName: "arrow.right.circle.fill")
                }.font(.body)
                .frame(width: 300, height: 50)
                #if os(iOS)
                .foregroundColor(.white)
                .background(color)
                .cornerRadius(15)
                #endif
            }
            .padding(.bottom)
        }
        .onAppear {
            loadData()
        }
        #if os(macOS)
        .padding(25)
        .frame(width: 600, height: 600)
        #endif
    }
    
    public var sheetHistory: some View {
        VStack(alignment: align) {
            Spacer()
            Text("History").bold().font(.largeTitle)
            Spacer()
            ScrollView(showsIndicators: false) {
                ForEach(items, id: \.self) { item in
                    ZStack {
                        color.opacity(0.25)
                        Text(item.version).bold().font(.title2).foregroundColor(color)
                    }.frame(width: 75, height: 30)
                    .cornerRadius(15)
                    .padding(.bottom)
                    ForEach(item.new, id: \.self) { new in
                        HStack {
                            ZStack {
                                color
                                Image(systemName: new.icon)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height:50)
                            .cornerRadius(15)
                            .padding(.trailing)
                            VStack(alignment: .leading) {
                                Text(new.title).font(.headline).lineLimit(1)
                                Text(new.subtitle).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                                Text(new.body).font(.caption).foregroundColor(.secondary).lineLimit(2)
                            }
                            Spacer()
                        }.padding(.bottom)
                    }
                }
            }.frame(width: 300)
            .frame(maxHeight: 450)
            Spacer()
            Button(action: { historySheet = false }) {
                HStack{
                    Text("Return").bold()
                    Image(systemName: "arrow.down.circle.fill")
                }.font(.body)
                .frame(width: 300, height: 50)
                #if os(iOS)
                .foregroundColor(.white)
                .background(color)
                .cornerRadius(15)
                #endif
            }
            .padding(.bottom)
        }
        #if os(macOS)
        .padding()
        .frame(width: 600, height: 600)
        #endif
    }

    public func compareVersion() {
        if Double(Bundle.version)! > version || Double(Bundle.build)! > build {
            withAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if showDrop {
                        #if os(iOS)
                        drop()
                        #endif
                    } else {
                        show = true
                    }
                }
                version = Double(Bundle.version)!
                build = Double(Bundle.build)!
            }
        }
    }
    public func loadData() {
        if data.contains("http") {
            // MARK: Remote Data
            let url = URL(string: data)
            URLSession.shared.dataTask(with: url!) { data, response, error in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        items = try decoder.decode([Vmodel].self, from: data)
                        self.loading = false
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        } else {
            // MARK: Local Data
            if let url = Bundle.main.url(forResource: data, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    items = try decoder.decode([Vmodel].self, from: data)
                    loading = false
                } catch {
                    print("error: \(error)")
                }
            }
        }
    }
    
    #if os(iOS)
    public func drop() {
        let drop = Drop( title: "Tap", subtitle: "To See What's New.", icon: UIImage(systemName: labelImage),
                         action: .init {
                                        Drops.hideCurrent()
                                        show = true
                                },
                         position: .top, duration: 3.0, accessibility: "Alert: Tap to see what's new." )
        Drops.show(drop)
    }
    #endif
}

// MARK: - Model
public struct Vmodel: Codable, Hashable {
    var version: String
    var new: [Model]
}
public struct Model: Codable, Hashable {
    var icon: String
    var title: String
    var subtitle: String
    var body: String
}

extension Bundle {
    var iconFileName: String? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last
        else { return nil }
        return iconFileName
    }
}

struct AppIcon: View {
    var body: some View {
        Bundle.main.iconFileName
            .flatMap { UIImage(named: $0) }
            .map { Image(uiImage: $0)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .overlay(
                            RoundedRectangle(cornerRadius: 19)
                                .stroke(.gray, lineWidth: 1)
                        )
            }
    }
}

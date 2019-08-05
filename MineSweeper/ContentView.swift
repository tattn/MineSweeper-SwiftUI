//
//  ContentView.swift
//  MineSweeper
//
//  Created by 田中達也 on 2019/07/11.
//  Copyright © 2019 Tatsuya Tanaka. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        VStack {
            Text("Mine Sweeper")
            MineSweeperView(size: 20)
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

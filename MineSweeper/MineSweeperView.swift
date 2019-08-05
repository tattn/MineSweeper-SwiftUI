//
//  MineSweeperView.swift
//  MineSweeper
//
//  Created by 田中達也 on 2019/07/11.
//  Copyright © 2019 Tatsuya Tanaka. All rights reserved.
//

import SwiftUI
import Combine
import Vision

final class GameManager: ObservableObject {
    @Published var scene: Scene = .playing
    @Published var cells: Cells
    private var cancellables: [AnyCancellable] = []

    init(cellSize: Int) {
        self.cells = Cells(size: cellSize)
        cells.objectWillChange.sink { _ in self.objectWillChange.send() }.store(in: &cancellables)
    }

    func openCell(atIndex index: Int) {
        guard case .closed = self.cells.board[index] else { return }
        withAnimation {
            if !self.cells.open(index: index) {
                self.scene = .gameOver
            } else if self.cells.restOfCell == self.cells.numberOfMines {
                self.scene = .gameClear
            }
        }
    }

    func toggleFlag(atIndex index: Int) {
        guard case .closed(let flag) = self.cells.board[index] else { return }
        self.cells.board[index] = .closed(flag: !flag)
    }

    func restartGame() {
        self.cells.reset()
        self.scene = .playing
    }
    
    enum Scene {
        case playing, gameOver, gameClear
    }
}

enum Cell: Equatable {
    case closed(flag: Bool = false), open(Open)
    var unrevealed: Bool {
        self == .closed(flag: false) || self == .closed(flag: true)
    }

    enum Open: Equatable {
        case mine, empty, number(Int)
    }
}

final class Cells: ObservableObject {
    let size: Int
    @Published var board: [Cell] = []
    private(set) var mines: [Bool] = []
    private(set) var numberOfMines: Int = 0

    var restOfCell: Int {
        board.filter({ $0.unrevealed }).count
    }
    
    init(size: Int) {
        self.size = size
        reset()
    }

    func reset() {
        board = Array(repeating: Cell.closed(), count: size*size)
        numberOfMines = Int(Double(size) * 1.5)
        mines = (Array(repeating: true, count: numberOfMines) + Array(repeating: false, count: size*size-numberOfMines)).shuffled()
    }
    
    @discardableResult
    func open(index: Int, recursive: Bool = false) -> Bool {
        guard case .closed = board[index] else { return true }
        if mines[index] {
            if recursive { return true }
            board[index] = .open(.mine)
            return false
        }

        let indices = self.indices(aroundIndex: index)
        let numberOfMines = indices.filter({ mines[$0] }).count
        if numberOfMines == 0 {
            board[index] = .open(.empty)
            indices.filter({ board[$0].unrevealed }).forEach { open(index: $0, recursive: true) }
        } else {
            board[index] = .open(.number(numberOfMines))
        }
        return true
    }
    
    func indices(aroundIndex index: Int) -> [Int] {
        ((index % size == 0 ? [] : [ // left edge
            index - size - 1,
            index        - 1,
            index + size - 1,
        ]) +
        ((index + 1) % size == 0 ? [] : [ // right edge
            index - size + 1,
            index        + 1,
            index + size + 1,
        ]) +
        [
            index - size,
            index + size,
        ]).filter { 0 <= $0 && $0 < board.count }
    }
}

struct CellView: View {
    let index: Int
    @EnvironmentObject private var gameManager: GameManager
    
    var body: some View {
        view(with: gameManager.cells.board[index])
            .minimumScaleFactor(0.1)
            .onTapGesture { self.gameManager.openCell(atIndex: self.index) }
            .onLongPressGesture { self.gameManager.toggleFlag(atIndex: self.index) }
    }
    
    private func view(with state: Cell) -> AnyView {
        switch state {
        case .closed(let flag):
            return ZStack {
                Color.blue
                flag ? Text("🚩") : nil
            }.erased
        case .open(let openState):
            switch openState {
            case .mine: return Text("💣").erased
            case .empty: return Text("").erased
            case .number(let number): return Text(number.description).erased
            }
        }
    }
}

struct Grid<Content: View>: View {
    let (width, height): (Int, Int)
    var content: (Int, Int) -> Content
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<self.height) { vIndex in
                HStack(spacing: 0) {
                    ForEach(0..<self.width) { hIndex in
                        self.content(hIndex, vIndex)
                    }
                }
            }
        }
    }
}

struct PlayView: View {
    @EnvironmentObject private var gameManager: GameManager
    var body: some View {
        GeometryReader { geometry -> AnyView in
            let cellSize = CGFloat(geometry.size.width) / CGFloat(self.gameManager.cells.size)
            return Grid(width: self.gameManager.cells.size, height: self.gameManager.cells.size) { hIndex, vIndex in
                CellView(index: vIndex * self.gameManager.cells.size + hIndex)
                    .frame(width: cellSize, height: cellSize)
                    .border(Color.black.opacity(0.2), width: 2)
            }.erased
        }
    }
}

struct ResultView: View {
    let title: String
    let titleColor: Color
    let tapRestart: () -> Void
    var body: some View {
        VStack {
            Text(title).foregroundColor(titleColor).font(.title)
            Button("Restart", action: tapRestart)
        }
    }
}

struct MineSweeperView: View {
    @ObservedObject private var gameManager: GameManager
    init(size: Int) {
        self.gameManager = GameManager(cellSize: size)
    }
    var body: some View {
        switch gameManager.scene {
        case .playing:
            return PlayView().environmentObject(gameManager).erased
        case .gameClear:
            return ResultView(title: "Game Clear", titleColor: .yellow, tapRestart: gameManager.restartGame).erased
        case .gameOver:
            return ResultView(title: "Game Over", titleColor: .red, tapRestart: gameManager.restartGame).erased
        }
    }
}

extension View {
    var erased: AnyView { AnyView(self) }
}

#if DEBUG
struct MineSweeperView_Previews : PreviewProvider {
    static var previews: some View {
        MineSweeperView(size: 5)
    }
}
#endif

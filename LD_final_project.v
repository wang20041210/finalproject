module LD_final_project(
    output reg [7:0] DATA_R, DATA_G, DATA_B,
    output reg [6:0] d7_1,
    output reg [2:0] COMM,
    output reg [1:0] COMM_CLK,
    output EN,
    input CLK, clear, Left, Right
);
    // -----------------------------
    // 參數 / 暫存器宣告
    // -----------------------------
    reg [7:0] barrier [7:0];   // 障礙物顯示用
    reg [7:0] player  [7:0];   // 玩家顯示用(上面程式:玩家只佔一列)

    // 七段顯示器相關
    reg [6:0] seg1, seg2;
    reg [3:0] bcd_s, bcd_m;

    // 7 段顯示器輸出
    wire A0,B0,C0,D0,E0,F0,G0;
    wire A1,B1,C1,D1,E1,F1,G1;
    segment7 S0(bcd_s, A0,B0,C0,D0,E0,F0,G0);
    segment7 S1(bcd_m, A1,B1,C1,D1,E1,F1,G1);

    // 除頻器
    wire CLK_div, CLK_time, CLK_mv;
    divfreq  div0(CLK, CLK_div);
    divfreq1 div1(CLK, CLK_time);
    divfreq2 div2(CLK, CLK_mv);

    // 掃描用
    reg [2:0] count;    //矩陣 
    reg       count1;   //七段

    // 玩家位置
    byte line;        

    // 按鍵暫存
    reg left, right;

    // 碰撞次數(一碰就結束 → touch=1)
    integer touch;

    // -----------------------------
    //  5 個掉落物
    //   a,b,c,d,e 為計數器
    //   r,r1,r2,r3,r4 為對應 row
    //   random01~random05 用於隨機行
    // -----------------------------
    integer a,b,c,d,e;
    reg [2:0] r,r1,r2,r3,r4;
    reg [2:0] random01, random02, random03, random04, random05;

    // -----------------------------
    // 初始值
    // -----------------------------
    initial begin
        bcd_m  = 0;
        bcd_s  = 0;
        line   = 3;
        touch  = 0;

        // 隨機數
            random01 = (5*random01 + 3)%16;
            r  = random01 % 8;
            random02 = (random01 + 1)%16;
            r1 = random02 % 8;
            random03=  (random01 + 2)%16;
            r2 = random03 % 8;
            random04=  (random01 + 3)%16;
            r3 = random04 % 8;
            random05=  (random01 + 4)%16;
            r4 = random05 % 8;

        a=0; b=0; c=0; d=0; e=0;

        DATA_R = 8'b11111111;
        DATA_G = 8'b11111111;
        DATA_B = 8'b11111111;

        barrier[0] = 8'b11111111;
        barrier[1] = 8'b11111111;
        barrier[2] = 8'b11111111;
        barrier[3] = 8'b11111111;
        barrier[4] = 8'b11111111;
        barrier[5] = 8'b11111111;
        barrier[6] = 8'b11111111;
        barrier[7] = 8'b11111111;

        player[0] = 8'b11111111;
        player[1] = 8'b11111111;
        player[2] = 8'b11111111;
        player[3] = 8'b00111111; // 玩家初始位置
        player[4] = 8'b11111111;
        player[5] = 8'b11111111;
        player[6] = 8'b11111111;
        player[7] = 8'b11111111;

        count1=0;
    end

    // -----------------------------
    // 七段顯示器
    // -----------------------------
    always @(posedge CLK_div) begin
        seg1[0] = A0; seg1[1] = B0; seg1[2] = C0;
        seg1[3] = D0; seg1[4] = E0; seg1[5] = F0; seg1[6] = G0;
        
        seg2[0] = A1; seg2[1] = B1; seg2[2] = C1;
        seg2[3] = D1; seg2[4] = E1; seg2[5] = F1; seg2[6] = G1;
        
        if(count1 == 0) begin
            d7_1 <= seg1;
            COMM_CLK[1] <= 1'b1;
            COMM_CLK[0] <= 1'b0;
            count1 <= 1'b1;
        end
        else begin
            d7_1 <= seg2;
            COMM_CLK[1] <= 1'b0;
            COMM_CLK[0] <= 1'b1;
            count1 <= 1'b0;
        end
    end

    // -----------------------------
    // 計時 & 進位 (00~99)
    // -----------------------------
    always @(posedge CLK_time or posedge clear) begin
        if(clear) begin
            bcd_m <= 4'd0;
            bcd_s <= 4'd0;
        end
        else begin
            // 碰到就結束 => touch < 1 表示還沒碰到
            if(touch < 1) begin
                if(bcd_s >= 9) begin
                    bcd_s <= 0;
                    bcd_m <= bcd_m + 1;
                end
                else
                    bcd_s <= bcd_s + 1;
                if(bcd_m >= 9) bcd_m <= 0;
            end
        end
    end

    // -----------------------------
    // 主畫面的視覺暫留
    // -----------------------------
    always @(posedge CLK_div) begin
        if(count >= 7)
            count <= 0;
        else
            count <= count + 1;
        COMM <= count;
        EN   <= 1'b1;

        // 若未碰撞
        if(touch < 1) begin
            DATA_G <= barrier[count];
            DATA_R <= player[count];
        end
        else begin
            // Game Over
            DATA_R <= barrier[count];
            DATA_G <= 8'b11111111;
        end
    end

    // -----------------------------
    // 遊戲邏輯: 增加到 5 個掉落物
    // -----------------------------
    always @(posedge CLK_mv) begin
        // 按鍵同步
        right = Right;
        left  = Left;

        if(clear == 1) begin
            // 遊戲重置
            touch = 0;
            line  = 3;

            a=0; b=0; c=0; d=0; e=0;

            

            barrier[0] = 8'b11111111;  // 全部清空
            barrier[1] = 8'b11111111;
            barrier[2] = 8'b11111111;
            barrier[3] = 8'b11111111;
            barrier[4] = 8'b11111111;
            barrier[5] = 8'b11111111;
            barrier[6] = 8'b11111111;
            barrier[7] = 8'b11111111;

            player[0] = 8'b11111111;
            player[1] = 8'b11111111;
            player[2] = 8'b11111111;
            player[3] = 8'b00111111;
            player[4] = 8'b11111111;
            player[5] = 8'b11111111;
            player[6] = 8'b11111111;
            player[7] = 8'b11111111;
        end
        else if(touch < 1) begin
            // ------------------------------------------------
            // fall object 1:  a, r
            // ------------------------------------------------
            if(a == 0) begin
                barrier[r][a] = 1'b0;
                a = a+1;
            end
            else if (a > 0 && a <= 7) begin
                barrier[r][a-1] = 1'b1;
                barrier[r][a]   = 1'b0;
                a = a+1;
            end
            else if(a == 8) begin
                barrier[r][7]   = 1'b1; // 這裡把最後位置清回 1
                random01 = (5*random01 + 3)%16;
                r = 6;//random01 % 8
                a = 0;
            end

            // ------------------------------------------------
            // fall object 2:  b, r1
            // ------------------------------------------------
            if(b == 0) begin
                barrier[r1][b] = 1'b0;
                b = b+1;
            end
            else if (b > 0 && b <= 7) begin
                barrier[r1][b-1] = 1'b1;
                barrier[r1][b]   = 1'b0;
                b = b+1;
            end
            else if(b == 8) begin
                barrier[r1][7]  = 1'b1;
                random02 = (5*(random02+1) + 3)%16;
                r1 = 6;
                b = 0;
            end

            // ------------------------------------------------
            // fall object 3:  c, r2
            // ------------------------------------------------
            if(c == 0) begin
                barrier[r2][c] = 1'b0;
                c = c+1;
            end
            else if (c > 0 && c <= 7) begin
                barrier[r2][c-1] = 1'b1;
                barrier[r2][c]   = 1'b0;
                c = c+1;
            end
            else if(c == 8) begin
                barrier[r2][7] = 1'b1;
                random03= (5*(random03+2) + 3)%16;
                r2 = 6;
                c = 0;
            end

            // ------------------------------------------------
            // fall object 4:  d, r3
            // ------------------------------------------------
            if(d == 0) begin
                barrier[r3][d] = 1'b0;
                d = d+1;
            end
            else if (d > 0 && d <= 7) begin
                barrier[r3][d-1] = 1'b1;
                barrier[r3][d]   = 1'b0;
                d = d+1;
            end
            else if(d == 8) begin
                barrier[r3][7]  = 1'b1;
                random04= (5*(random04+3) + 3)%16;
                r3 = 7;
                d = 0;
            end

            // ------------------------------------------------
            // fall object 5:  e, r4
            // ------------------------------------------------
            if(e == 0) begin
                barrier[r4][e] = 1'b0;
                e = e+1;
            end
            else if (e > 0 && e <= 7) begin
                barrier[r4][e-1] = 1'b1;
                barrier[r4][e]   = 1'b0;
                e = e+1;
            end
            else if(e == 8) begin
                barrier[r4][7]  = 1'b1;
                random05= (5*(random05+4) + 3)%16;
                r4 = 7;
                e = 0;
            end

            // 玩家移動
            if(right && (line != 7)) begin
                // 清除舊位置
                player[line][6] = 1'b1;
                player[line][7] = 1'b1;
                line = line + 1;
            end
            if(left && (line != 0)) begin
                player[line][6] = 1'b1;
                player[line][7] = 1'b1;
                line = line - 1;
            end
            // 舊位置
            player[line][6] = 1'b0;
            player[line][7] = 1'b0;

            // 碰撞(一碰就結束 → touch=1)
            if(barrier[line][6] == 0 || barrier[line][7] == 0) begin
                touch = 1;  // game over
            end
        end
        else begin
            // game over → 顯示 Game Over(GO)
            barrier[0] = 8'b10000001;
            barrier[1] = 8'b01111110;
            barrier[2] = 8'b01101110;
            barrier[3] = 8'b10001101;
            barrier[4] = 8'b10000001;
            barrier[5] = 8'b01111110;
            barrier[6] = 8'b01111110;
            barrier[7] = 8'b10000001;
        end
    end

endmodule

//----------------------------------------------------
//7段顯示器
//----------------------------------------------------
module segment7(
    input  [3:0] a,
    output reg A,B,C,D,E,F,G
);
always @(*) begin
    case(a)
        4'd0: {A,B,C,D,E,F,G} = 7'b0000001; // 0
        4'd1: {A,B,C,D,E,F,G} = 7'b1001111; // 1
        4'd2: {A,B,C,D,E,F,G} = 7'b0010010; // 2
        4'd3: {A,B,C,D,E,F,G} = 7'b0000110; // 3
        4'd4: {A,B,C,D,E,F,G} = 7'b1001100; // 4
        4'd5: {A,B,C,D,E,F,G} = 7'b0100100; // 5
        4'd6: {A,B,C,D,E,F,G} = 7'b0100000; // 6
        4'd7: {A,B,C,D,E,F,G} = 7'b0001111; // 7
        4'd8: {A,B,C,D,E,F,G} = 7'b0000000; // 8
        4'd9: {A,B,C,D,E,F,G} = 7'b0000100; // 9
        default: {A,B,C,D,E,F,G} = 7'b1111111;    
	 endcase
end
endmodule


//----------------------------------------------------
// 視覺暫留
//----------------------------------------------------
module divfreq(input CLK, output reg CLK_div);
  reg [24:0] Count;
  always @(posedge CLK) begin
    if(Count > 5000) begin
      Count <= 0;
      CLK_div <= ~CLK_div;
    end else
      Count <= Count + 1'b1;
  end
endmodule

//----------------------------------------------------
// 計時用
//----------------------------------------------------
module divfreq1(input CLK, output reg CLK_time);
  reg [25:0] Count;
  initial CLK_time = 0;
  always @(posedge CLK) begin
    if(Count > 25000000) begin
      Count <= 0;
      CLK_time <= ~CLK_time;
    end else
      Count <= Count + 1'b1;
  end
endmodule

//----------------------------------------------------
// 掉落用
//----------------------------------------------------
module divfreq2(input CLK, output reg CLK_mv);
  reg [35:0] Count;
  initial CLK_mv = 0;
  always @(posedge CLK) begin
    if(Count > 5500000) begin
      Count <= 0;
      CLK_mv <= ~CLK_mv;
    end else
      Count <= Count + 1'b1;
  end
endmodule

























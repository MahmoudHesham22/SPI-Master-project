class spi_ref_model;

    int error_count = 0;

    bit        reg_ctrl_en;
    bit        reg_ctrl_mstr;
    bit [1:0]  reg_ctrl_mode;
    bit        reg_ctrl_lsb_first;
    bit        reg_ctrl_loopback;
    bit [1:0]  reg_ctrl_width;
    bit [15:0] reg_clk_div;
    bit [3:0]  reg_ss_en;
    bit [3:0]  reg_ss_val;
    bit [4:0]  reg_int_en;
    bit [4:0]  reg_int_stat;
    bit [7:0]  reg_delay;

    bit [31:0] tx_fifo[$];
    bit [31:0] rx_fifo[$];

    function automatic int width_to_bits(input bit [1:0] w);
        case (w)
            2'b00: return 8;
            2'b01: return 16;
            default: return 32;
        endcase
    endfunction

    function new();
        // initialise inline (cannot call task from function)
        error_count        = 0;
        reg_ctrl_en        = 1'b0;
        reg_ctrl_mstr      = 1'b0;
        reg_ctrl_mode      = 2'b00;
        reg_ctrl_lsb_first = 1'b0;
        reg_ctrl_loopback  = 1'b0;
        reg_ctrl_width     = 2'b00;
        reg_clk_div        = 16'h0;
        reg_ss_en          = 4'h0;
        reg_ss_val         = 4'h0;
        reg_int_en         = 5'h0;
        reg_int_stat       = 5'h0;
        reg_delay          = 8'h0;
        tx_fifo.delete();
        rx_fifo.delete();
    endfunction

    function void reset();
        error_count        = 0;
        reg_ctrl_en        = 1'b0;
        reg_ctrl_mstr      = 1'b0;
        reg_ctrl_mode      = 2'b00;
        reg_ctrl_lsb_first = 1'b0;
        reg_ctrl_loopback  = 1'b0;
        reg_ctrl_width     = 2'b00;
        reg_clk_div        = 16'h0;
        reg_ss_en          = 4'h0;
        reg_ss_val         = 4'h0;
        reg_int_en         = 5'h0;
        reg_int_stat       = 5'h0;
        reg_delay          = 8'h0;
        tx_fifo.delete();
        rx_fifo.delete();
    endfunction

    function void model_apb_write(input bit [7:0] addr, input bit [31:0] data);
        case (addr)
            APB_CTRL: begin
                reg_ctrl_width     = data[7:6];
                reg_ctrl_loopback  = data[5];
                reg_ctrl_lsb_first = data[4];
                reg_ctrl_mode      = data[3:2];
                reg_ctrl_mstr      = data[1];
                reg_ctrl_en        = data[0];
                if (!reg_ctrl_en) begin
                    tx_fifo.delete();
                    rx_fifo.delete();
                end
            end
            APB_TX_DATA: begin
                if (reg_ctrl_en) begin
                    bit [31:0] masked;
                    case (reg_ctrl_width)
                        2'b00: masked = {24'h0, data[7:0]};
                        2'b01: masked = {16'h0, data[15:0]};
                        default: masked = data;
                    endcase
                    if (tx_fifo.size() < 8)
                        tx_fifo.push_back(masked);
                    else
                        reg_int_stat[2] = 1'b1;
                end
            end
            APB_CLK_DIV:  reg_clk_div  = data[15:0];
            APB_SS_CTRL: begin
                reg_ss_val = data[7:4];
                reg_ss_en  = data[3:0];
            end
            APB_INT_EN:   reg_int_en   = data[4:0];
            APB_INT_STAT: reg_int_stat = reg_int_stat & ~data[4:0];
            APB_DELAY:    reg_delay    = data[7:0];
            default: ;
        endcase
    endfunction

    function void model_transfer(input bit [31:0] miso_in);
        bit [31:0] tx_word, rx_word, miso_masked;
        if (tx_fifo.size() == 0) return;
        tx_word = tx_fifo.pop_front();
        case (reg_ctrl_width)
            2'b00: miso_masked = {24'h0, miso_in[7:0]};
            2'b01: miso_masked = {16'h0, miso_in[15:0]};
            default: miso_masked = miso_in;
        endcase
        rx_word = reg_ctrl_loopback ? tx_word : miso_masked;
        if (rx_fifo.size() < 8) begin
            rx_fifo.push_back(rx_word);
            if (rx_fifo.size() == 8) reg_int_stat[1] = 1'b1;
        end else begin
            reg_int_stat[3] = 1'b1;
        end
        if (tx_fifo.size() == 0) reg_int_stat[0] = 1'b1;
        reg_int_stat[4] = 1'b1;
    endfunction

    function void check_rx(input bit [31:0] observed);
        bit [31:0] expected;
        expected = (rx_fifo.size() == 0) ? 32'h0 : rx_fifo.pop_front();
        if (observed !== expected) begin
            $display("[SCOREBOARD_ERROR] RX mismatch: expected=0x%08h observed=0x%08h",
                     expected, observed);
            error_count++;
        end
    endfunction

    function void check_reg(input string name,
                            input bit [31:0] expected,
                            input bit [31:0] observed);
        if (observed !== expected) begin
            $display("[SCOREBOARD_ERROR] %s mismatch: expected=0x%08h observed=0x%08h",
                     name, expected, observed);
            error_count++;
        end
    endfunction

    function void check_irq(input bit [4:0] observed_stat,
                            input bit [4:0] observed_irq_level);
        if (observed_stat !== reg_int_stat) begin
            $display("[SCOREBOARD_ERROR] INT_STAT mismatch: expected=0x%02h observed=0x%02h",
                     reg_int_stat, observed_stat);
            error_count++;
        end
    endfunction

endclass

`endif

class spi_ref_model;

    // Register address parameters
    localparam [7:0] APB_CTRL     = 8'h00;
    localparam [7:0] APB_STATUS   = 8'h04;
    localparam [7:0] APB_TX_DATA  = 8'h08;
    localparam [7:0] APB_RX_DATA  = 8'h0C;
    localparam [7:0] APB_CLK_DIV  = 8'h10;
    localparam [7:0] APB_SS_CTRL  = 8'h14;
    localparam [7:0] APB_INT_EN   = 8'h18;
    localparam [7:0] APB_INT_STAT = 8'h1C;
    localparam [7:0] APB_DELAY    = 8'h20;

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

    function bit [31:0] expected_apb_read(input bit [7:0] addr);
        case (addr)
            APB_CTRL:    return {24'h0, reg_ctrl_width, reg_ctrl_loopback, reg_ctrl_lsb_first, reg_ctrl_mode, reg_ctrl_mstr, reg_ctrl_en};
            APB_TX_DATA: return 32'h0;
            APB_CLK_DIV: return {16'h0, reg_clk_div};
            APB_SS_CTRL: return {24'h0, reg_ss_val, reg_ss_en};
            APB_INT_EN:  return {{27{1'b0}}, reg_int_en};
            APB_INT_STAT:return {{27{1'b0}}, reg_int_stat};
            APB_DELAY:   return {24'h0, reg_delay};
            default:     return 32'h0;
        endcase
    endfunction

    function bit expected_irq();
        return |(reg_int_stat & reg_int_en);
    endfunction

    function bit [3:0] expected_ss_n();
        return (~reg_ss_en) | reg_ss_val;
    endfunction

    function bit do_action(input apb_sequence_item apb_item,
                             input spi_sequence_item spi_item);
        bit match;
        bit [31:0] expected_prdata;

        // Drive the reference model state from the APB transaction inputs.
        match = 1'b1;

        if (apb_item.PSEL && apb_item.PENABLE && apb_item.PWRITE) begin
            model_apb_write(apb_item.PADDR, apb_item.PWDATA);
        end

        // Compare DUT read data against the ref model's expected read output.
        if (apb_item.PSEL && apb_item.PENABLE && !apb_item.PWRITE) begin
            expected_prdata = expected_apb_read(apb_item.PADDR);
            if (apb_item.PRDATA !== expected_prdata) begin
                $display("[DO_ACTION] PRDATA mismatch at addr 0x%02h: expected=0x%08h actual=0x%08h",
                         apb_item.PADDR, expected_prdata, apb_item.PRDATA);
                match = 1'b0;
            end
        end

        // Compare DUT SPI outputs against the reference model outputs.
        if (spi_item.SS_n !== expected_ss_n()) begin
            $display("[DO_ACTION] SS_n mismatch: expected=0x%01h actual=0x%01h",
                     expected_ss_n(), spi_item.SS_n);
            match = 1'b0;
        end

        if (spi_item.IRQ !== expected_irq()) begin
            $display("[DO_ACTION] IRQ mismatch: expected=%0b actual=%0b",
                     expected_irq(), spi_item.IRQ);
            match = 1'b0;
        end

        return match;
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



`timescale 1ns/1ps

module decimacao_tb;

    integer f, i;
    reg [7:0] tmp_pixel;

    // DUT
    decimacao uut();

    initial begin
        #1; // espera processamento do módulo

        f = $fopen("saida.mem", "w");
        for (i = 0; i < 40*30; i = i + 1) begin
            tmp_pixel = uut.memoria_saida[i];  // acesso direto à memória interna
            $fwrite(f, "%02h\n", tmp_pixel);
        end
        $fclose(f);

        $display("✅ Processamento concluído, arquivo saida.mem criado!");
        $finish;
    end

endmodule

`timescale 1ns/1ps

module zoom_nn_tb;

    integer f, i;
    reg [7:0] tmp_pixel;

    // Instancia o DUT (Device Under Test)
    zoom_nn uut();

    initial begin
        #1; // espera processamento do módulo

        f = $fopen("saida.mem", "w");
        for (i=0; i<320*240; i=i+1) begin
            tmp_pixel = uut.memoria_saida[i];  // <<< ACESSO DIRETO À MEMÓRIA INTERNA
            $fwrite(f, "%02h\n", tmp_pixel);
        end
        $fclose(f);

        $display("✅ Processamento concluído, arquivo saida.mem criado!");
        $finish;
    end

endmodule

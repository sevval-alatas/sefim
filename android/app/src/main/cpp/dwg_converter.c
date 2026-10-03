#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dwg.h>
#include <dwg_api.h>

#ifdef __cplusplus
extern "C" {
#endif

int convert_dwg_to_dxf(const char *input_path, const char *output_path) {
    if (!input_path || !output_path) {
        return -1;
    }

    Dwg_Data dwg;
    Bit_Chain dat;

    memset(&dwg, 0, sizeof(Dwg_Data));
    memset(&dat, 0, sizeof(Bit_Chain));

    int read_res = dwg_read_file(input_path, &dwg);
    if (read_res >= DWG_ERR_CRITICAL) {
        dwg_free(&dwg);
        return read_res;
    }

    dat.fh = fopen(output_path, "wb");
    if (!dat.fh) {
        dwg_free(&dwg);
        return -2;
    }

    int write_res = dwg_write_dxf(&dat, &dwg);
    fclose(dat.fh);
    dwg_free(&dwg);

    return write_res;
}

#ifdef __cplusplus
}
#endif

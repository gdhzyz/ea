
sr_list = [48, 96, 192] # sample rate, in KHz
width_list = [16, 32] # data width
tdm_list = [2, 4, 8, 16] # TDM number

mclki = 24.576 # MHz

for sr in sr_list:
    for width in width_list:
        for tdm in tdm_list:
            bclk = sr * 1000 * width * tdm
            bclk_mhz = bclk / 1000 /1000
            freq_factor = mclki / bclk_mhz
            if freq_factor >= 1:
                print(f'mclki {mclki}MHz sample_rate {sr:>3}KHz width {width}b tdm {tdm:>2}, bclk {bclk_mhz: =6.3f}MHz freq_factor {freq_factor: =6.3f}')

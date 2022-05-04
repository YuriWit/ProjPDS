%% setup
clear; close all; clc;
rng(1);
addpath("OTFS_sample_code/");
fileName = "VozEstudio.wav";
[y,Fs] = audioread(fileName);

wavbinary = dec2bin(typecast(single(y(:)), 'uint8'), 8) - '0';
wavb1=uint8(wavbinary);
w1=reshape(wavb1,15486976,1);

xmod=qammod(w1, 16, 'gray', 'inputtype', 'bit');;
y1=awgn(xmod,10);
rdmod=qamdemod(y1, 16, 'gray', 'outputtype', 'bit');
% rdmod1=reshape(rdmod,1935872,8);
rdmod2=uint8(rdmod);
data = uint8(bin2dec( char( reshape( rdmod2, 8,[]).'+'0')));
audiowrite(data, 'rec_roja.wav',8000)

% file_bits is now a vector of binary values ready for modulation.
% At the other end, demodulate into a vector of uint8, and do any 
% appropriate error correction. Then

fileName = "VozEstudioOTFS.wav";
outfid = fopen(filename, 'w');
fwrite(outfid, file_bits, 'bit1');
fclose(outfid);

%% OTFS parameters
% number of symbol
N = 8;
% number of subcarriers
M = 8;
% size of constellation
M_mod = 4;
M_bits = log2(M_mod);
% average energy per data symbol
eng_sqrt = (M_mod==2)+(M_mod~=2)*sqrt((M_mod-1)/6*(2^2));
% number of symbols per frame
N_syms_perfram = N*M;
% number of bits per frame
N_bits_perfram = N*M*M_bits;

SNR_dB = 20:2:20;
SNR = 10.^(SNR_dB/10);
noise_var_sqrt = sqrt(1./SNR);
sigma_2 = abs(eng_sqrt*noise_var_sqrt).^2;

%%
N_fram = 10^4;
err_ber = zeros(length(SNR_dB),1);
for iesn0 = 1:length(SNR_dB)
    for ifram = 1:N_fram
        %% random input bits generation%%%%%
        data_info_bit = randi([0,1],N_bits_perfram,1);
        data_temp = bi2de(reshape(data_info_bit,N_syms_perfram,M_bits));
        x = qammod(data_temp,M_mod,'gray');
        x = reshape(x,N,M);
        
        %% OTFS modulation%%%%
        s = OTFS_modulation(N,M,x);
        
        %% OTFS channel generation%%%%
        [taps,delay_taps,Doppler_taps,chan_coef] = OTFS_channel_gen(N,M);
        
        %% OTFS channel output%%%%%
        r = OTFS_channel_output(N,M,taps,delay_taps,Doppler_taps,chan_coef,sigma_2(iesn0),s);
        
        %% OTFS demodulation%%%%
        y = OTFS_demodulation(N,M,r);
        
        %% message passing detector%%%%
        x_est = OTFS_mp_detector(N,M,M_mod,taps,delay_taps,Doppler_taps,chan_coef,sigma_2(iesn0),y);
        
        %% output bits and errors count%%%%%
        data_demapping = qamdemod(x_est,M_mod,'gray');
        data_info_est = reshape(de2bi(data_demapping,M_bits),N_bits_perfram,1);
        errors = sum(xor(data_info_est,data_info_bit));
        err_ber(iesn0) = errors + err_ber(iesn0);
        ifram;
    end
end
err_ber_fram = err_ber/N_bits_perfram./N_fram;
semilogy(SNR_dB, err_ber_fram,'-*','LineWidth',2);
title(sprintf('OTFS'))
ylabel('BER'); xlabel('SNR in dB');grid on

toc



% OFDM modulation
% OTFS modulation
% channel modeling ofdm 
% channel modeling otfs
% transmisson over channel ofdm
% transmisson over channel otfs
% detection ofdm
% detection otfs
% ofdm demodulation
% otfs demodulation
% power evaluation
% distortion analisys
% plot relults
% save simulation data
% equalizations needs
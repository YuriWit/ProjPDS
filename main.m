%% setup
clear; close all; clc; rng(1);
addpath("OTFS_sample_code/");
%% get bytes
fileName = "VozEstudio.wav";
fileID = fopen(fileName,"r");
bytes = fread(fileID);
fclose(fileID);
clear fileID;
%% setup channel



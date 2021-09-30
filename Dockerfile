FROM jupyter/datascience-notebook:latest

RUN conda install requests 
#, openpyxl

ENV JUPYTER_ENABLE_LAB=yes
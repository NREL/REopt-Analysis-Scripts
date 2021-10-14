FROM jupyter/datascience-notebook:latest

RUN conda install requests openpyxl -y

ENV JUPYTER_ENABLE_LAB=yes
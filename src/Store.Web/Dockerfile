#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Store.Web/Store.Web.csproj", "Store.Web/"]
RUN dotnet restore "Store.Web/Store.Web.csproj"
COPY . .
WORKDIR "/src/Store.Web"
RUN dotnet build "Store.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Store.Web.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Store.Web.dll"]
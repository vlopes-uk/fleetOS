var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.TvdeFleet_Api>("tvdefleet-api");

builder.AddAzureFunctionsProject<Projects.TvdeFleet_Functions>("tvdefleet-functions");

builder.AddProject<Projects.TvdeFleet_MaponMock>("tvdefleet-maponmock");

builder.AddProject<Projects.TvdeFleet_Blazor>("tvdefleet-blazor");

builder.Build().Run();

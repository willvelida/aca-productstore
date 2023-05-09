using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.VisualStudio.TestPlatform.TestHost;
using System.Net;

namespace Store.ProductApi.IntegrationTests
{
    public class ProductApiShould : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;

        public ProductApiShould(WebApplicationFactory<Program> factory)
        {
            _factory = factory;
        }

        [Fact]
        public async Task ReturnOkWhenCallingGet()
        {
            // Arrange
            var client = _factory.CreateClient();

            // Act
            var response = await client.GetAsync(Environment.GetEnvironmentVariable("BLUE_SLOT_URL"));

            // Assert
            Assert.Equal((HttpStatusCode)StatusCodes.Status200OK, response.StatusCode);
        }
    }
}
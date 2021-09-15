require 'spec_helper'

describe Spree::Webhooks::Endpoints::MakeRequestJob, :inline_jobs do
:wa
  let(:url) { 'http://url.com/' }

  it 'it enqueues a HTTP request using Spree::Webhooks::Endpoints::MakeRequest' do
    expect { described_class.perform_later(url) }.to(
      have_enqueued_job.on_queue('spree_webhooks')
    )
  end
end

# bundle exec ruby generate_invoice.rb --numero 05 --name "Juillet 2024" --days "15" --taux-journalier-moyen "500"

require 'invoice_printer'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_invoice.rb [options]"

  opts.on("-num", "--numero NUMERO", "Invoice number") do |n|
    options[:numero] = n
  end

  opts.on("-name", "--name NAME", "Invoice name") do |n|
    options[:name] = n
  end

  opts.on("-days", "--days DAYS", "Number of worked days") do |n|
    options[:days] = n.to_f
  end

  opts.on("-tjm", "--taux-journalier-moyen TJM", "Taux journalier moyen") do |n|
    options[:tjm] = n.to_i
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

unless options[:numero]
  puts "Missing required option: --numero NUMERO"
  puts "Use -h for help."
  exit
end

unless options[:name]
  puts "Missing required option: --name NAME"
  puts "Use -h for help."
  exit
end

today = Date.today
full_num = "2025-#{options[:numero].rjust(3, '0')}"

def euro(number)
  format '%.2f €', number
end

def format_item(item_raw)
  InvoicePrinter::Document::Item.new(
    name: item_raw.name,
    quantity: item_raw.quantity.to_s,
    price: euro(item_raw.price),
    amount: euro(item_raw.amount)
    # tax: euro(item_raw.tax)
  )
end

item_raw_struct = Struct.new(:name, :quantity, :price) do
  def amount
    price * quantity
  end

  def tax
    0.2 * amount
  end

  def ttc
    amount + tax
  end
end

items_raw = [
  ["Jours de travail\nRDV Service Public", options[:days], options[:tjm]],
].map { item_raw_struct.new(*_1) }

total_ttc = items_raw.map(&:ttc).sum
file_name = "Facture #{full_num} - Scopyleft - RDV Service Public #{options[:name]} - #{total_ttc.floor}eur.pdf"


InvoicePrinter.labels = {
  name: options[:name],
  provider: 'Émetteur',
  purchaser: 'Destinataire',
  tax_id: 'Numéro de TVA',
  payment: 'Règlement',
  payment_by_transfer: "Règlement par virement bancaire à l'IBAN suivant:",
  account_number: '',
  swift: 'SWIFT',
  iban: 'IBAN',
  issue_date: "Date d'émission",
  due_date: 'Date limite de règlement',
  item: 'Item',
  variable: '',
  quantity: 'Quantité',
  price_per_item: 'Prix unitaire HT',
  amount: 'Total HT',
  tax: 'TVA 20%',
  subtotal: 'Total HT',
  total: 'Total TTC'
}

InvoicePrinter.print(
  document: InvoicePrinter::Document.new(
    number: "Facture numéro #{full_num}",
    provider_name: 'Piano Piano',
    provider_lines: [
      '6 rue de la vigne, 22770, Lancieux',
      'adrien@pianopiano.fr',
      '84526029800037',
      'Numéro de TVA FR19845260298'
    ].join("\n"),
    purchaser_name: 'Scopyleft',
    purchaser_lines: [
      '199 Rue Hélène Boucher',
      '34170 Castelnau-le-Lez',
      'SIREN : 790 212 450',
      'Numéro de TVA FR42790212450'
    ].join("\n"),
    issue_date: today.strftime('%d/%m/%Y'),
    due_date: (today + 90).strftime('%d/%m/%Y'),
    subtotal: euro(items_raw.map(&:amount).sum),
    tax: euro(items_raw.map(&:tax).sum),
    total: euro(items_raw.map(&:amount).sum * 1.2),
    bank_account_number: [
      'FR76 1695 8000 0113 5599 9575 445',
      '',
      'BIC QNTOFRP1XXX'
    ].join("\n"),
    items: items_raw.map { format_item(_1) }
  ),
  file_name:,
  font: 'overpass'
)

`open "#{file_name}"`
